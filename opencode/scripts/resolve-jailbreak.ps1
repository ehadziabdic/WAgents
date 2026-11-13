# resolve-jailbreak.ps1 - pick exactly one jailbreak file for the model this session runs on.
#
#   .\resolve-jailbreak.ps1                 resolve for the current OpenCode session
#   .\resolve-jailbreak.ps1 -Model glm-5.3  resolve for an explicit model
#   .\resolve-jailbreak.ps1 -List           list available model files
#   .\resolve-jailbreak.ps1 -NoPull         never touch git
#   .\resolve-jailbreak.ps1 -Json           machine-readable output
#   .\resolve-jailbreak.ps1 -Root <dir>     resolve against another config root (testing)
#
# Matching order:
#   1. keyword shapes: a filename and a model id are reduced to the same
#      (family, versions, qualifiers) shape, so deepseek-v5-free finds
#      deepseek-v5.md with no table edit. Unique highest score wins; a tie
#      means "not sure" and falls through.
#   2. alias map in scripts/jailbreak-model-map.json: manual disambiguation
#      for irregular names (sonnet, opus) and genuine ties (glm-5.3,
#      glm-zcode-5.3). Never the primary matcher.
#   3. git pull --ff-only in the jailbreaks repo, then 1 and 2 again
#   4. no-match + the available list
#
# The script never reads or prints the contents of any jailbreak file.

param(
    [string]$Model,
    [string]$Provider,
    [switch]$List,
    [switch]$NoPull,
    [switch]$Json,
    [string]$Root
)

$ErrorActionPreference = "Stop"

$ConfigDir = if ($Root) { $Root } else { Join-Path $env:USERPROFILE ".config\opencode" }
$JailbreaksDir = Join-Path $ConfigDir "jailbreaks"
$MapFile = Join-Path $ConfigDir "scripts\jailbreak-model-map.json"
$ReadmeFile = Join-Path $JailbreaksDir "README.md"

function Normalize-Name([string]$s) {
    if (-not $s) { return "" }
    $n = $s.ToLowerInvariant()
    # provider/model separators and punctuation collapse to one hyphen
    $n = $n -replace '[\\/]', '-'
    $n = $n -replace '[^a-z0-9\.]+', '-'
    $n = $n -replace '-+', '-'
    $n = $n.Trim('-')
    # strip noise tails repeatedly: -free, -latest, -preview, -contributor, -thinking
    while ($true) {
        $next = $n -replace '-(free|latest|preview|contributor|thinking)$', ''
        if ($next -eq $n) { break }
        $n = $next
    }
    return $n
}

# --- keyword shapes -------------------------------------------------------
# A model id and a filename are reduced to the same three-part shape:
#   Family   = the word parts of the name, glued together (deepseek, glm, gpt...)
#   Versions = every number in order (4.1 -> 4,1 ; 5 -> 5)
#   Quals    = meaningful modifiers (flash, pro, ultra, large, mini...)
# Matching then compares shapes, so a file named deepseek-v5.md pins
# deepseek-v5-free without anyone editing a table.

$script:Qualifiers = @(
    'flash', 'pro', 'ultra', 'large', 'mini', 'nano', 'max', 'lite', 'air',
    'code', 'oss', 'build', 'argon', 'wonder', 'spark', 'omni', 'turbo',
    'fast', 'reasoning', 'vl', 'vision'
)

$script:Noise = @(
    'free', 'latest', 'preview', 'contributor', 'thinking', 'opencode',
    'agents', 'agent', 'md', 'prompt', 'config', 'model', 'instruct', 'chat'
)

function Get-Shape([string]$s) {
    if (-not $s) { return [PSCustomObject]@{ Family = ''; Versions = @(); Quals = @() } }
    $n = $s.ToLowerInvariant()
    if ($n.EndsWith('.md')) { $n = $n.Substring(0, $n.Length - 3) }

    $familyParts = New-Object System.Collections.Generic.List[string]
    $quals = New-Object System.Collections.Generic.List[string]

    foreach ($m in [regex]::Matches($n, '[a-z]+')) {
        $a = $m.Value
        if ($a.Length -lt 2) { continue }          # v, b, k -> version markers, not family
        if ($script:Noise -contains $a) { continue }
        if ($script:Qualifiers -contains $a) {
            if (-not $quals.Contains($a)) { $quals.Add($a) }
            continue
        }
        $familyParts.Add($a)
    }

    $versions = New-Object System.Collections.Generic.List[string]
    foreach ($m in [regex]::Matches($n, '\d+')) { $versions.Add($m.Value) }

    return [PSCustomObject]@{
        Family   = ($familyParts -join '')
        Versions = @($versions)
        Quals    = @($quals)
    }
}

function Test-FamilyMatch([string]$a, [string]$b) {
    if (-not $a -or -not $b) { return $false }
    if ($a -eq $b) { return $true }
    return ($a.Contains($b) -or $b.Contains($a))
}

# 3 = identical version run, 2 = model is a prefix of file (file more specific),
# 1 = file is a prefix of model (file less specific), 0 = unrelated
function Compare-Versions($modelVersions, $fileVersions) {
    $a = @($modelVersions)
    $b = @($fileVersions)
    $common = [Math]::Min($a.Count, $b.Count)
    for ($i = 0; $i -lt $common; $i++) {
        if ($a[$i] -ne $b[$i]) { return 0 }
    }
    if ($a.Count -eq $b.Count) { return 3 }
    if ($a.Count -lt $b.Count) { return 2 }
    return 1
}

function Resolve-Keyword([string]$model) {
    $mine = Get-Shape $model
    if (-not $mine.Family) { return $null }

    $candidates = @()
    foreach ($f in (Get-AvailableFiles)) {
        $theirs = Get-Shape $f.File
        if (-not (Test-FamilyMatch $mine.Family $theirs.Family)) { continue }

        $versionScore = Compare-Versions $mine.Versions $theirs.Versions
        if ($versionScore -eq 0) { continue }

        $qualScore = 0
        foreach ($q in $mine.Quals) {
            if ($theirs.Quals -contains $q) { $qualScore++ } else { $qualScore-- }
        }

        $score = ($versionScore * 2) + $qualScore
        if ($score -lt 2) { continue }

        $candidates += [PSCustomObject]@{
            File = $f.File; Label = $f.Label; Source = 'keyword'; Score = $score
        }
    }

    if ($candidates.Count -eq 0) { return $null }
    $sorted = @($candidates | Sort-Object Score -Descending)
    if ($sorted.Count -gt 1 -and $sorted[0].Score -eq $sorted[1].Score) { return $null }
    return $sorted[0]
}

function Get-Labels {
    $labels = @{}
    if (Test-Path $ReadmeFile) {
        $raw = Get-Content $ReadmeFile -Raw
        foreach ($line in ($raw -split "`n")) {
            if ($line -notmatch '^\|\s*\*\*(.+?)\*\*\s*\|(.+)$') { continue }
            $label = $Matches[1].Trim()
            $cells = $Matches[2]
            foreach ($m in [regex]::Matches($cells, '\[([^\]]+)\]\(\./([^)]+)\)')) {
                $file = [System.Uri]::UnescapeDataString($m.Groups[2].Value)
                if (-not $labels.ContainsKey($file)) { $labels[$file] = $label }
            }
        }
    }
    # explicit overrides win over the README (fixes slugs and duplicate labels)
    if (Test-Path $MapFile) {
        try {
            $map = Get-Content $MapFile -Raw | ConvertFrom-Json
            if ($map.labels) {
                foreach ($p in $map.labels.PSObject.Properties) {
                    if ($null -eq $p.Value) { $labels.Remove($p.Name) }
                    else { $labels[$p.Name] = [string]$p.Value }
                }
            }
        } catch { }
    }
    return $labels
}

function Get-AvailableFiles {
    if (-not (Test-Path $JailbreaksDir)) { return @() }
    $labels = Get-Labels
    $items = @()
    foreach ($f in (Get-ChildItem $JailbreaksDir -File -Filter '*.md' -ErrorAction SilentlyContinue)) {
        if ($f.Name -eq 'README.md') { continue }
        if ($f.Length -lt 200) { continue }
        if ($labels.ContainsKey($f.Name) -and -not $labels[$f.Name]) { continue }
        $label = if ($labels.ContainsKey($f.Name)) { $labels[$f.Name] } else { $f.BaseName }
        $items += [PSCustomObject]@{ Label = $label; File = $f.Name; Path = $f.FullName }
    }
    return @($items | Sort-Object Label)
}

function Test-SafeFile([string]$name) {
    if (-not $name) { return $false }
    if ($name -ne [System.IO.Path]::GetFileName($name)) { return $false }
    $p = Join-Path $JailbreaksDir $name
    return (Test-Path -LiteralPath $p -PathType Leaf)
}

function Resolve-Alias([string]$haystack, [string]$full) {
    if (-not (Test-Path $MapFile)) { return $null }
    $map = Get-Content $MapFile -Raw | ConvertFrom-Json
    foreach ($a in $map.aliases) {
        if (($haystack -match $a.pattern) -or ($full -match $a.pattern)) {
            if (Test-SafeFile $a.file) {
                return [PSCustomObject]@{ File = $a.file; Label = $a.label; Source = 'alias' }
            }
        }
    }
    return $null
}

function Resolve-Match([string]$model, [string]$provider) {
    # keyword shapes first: filenames decide, so new model files match with no table edit
    $hit = Resolve-Keyword $model
    if ($hit) { return $hit }

    # alias table second: only disambiguates irregular names and genuine ties
    $normalized = Normalize-Name $model
    $full = Normalize-Name ($provider + "-" + $model)
    return Resolve-Alias $normalized $full
}

function Update-Repo {
    if (-not (Test-Path (Join-Path $JailbreaksDir ".git"))) { return "not-a-git-repo" }
    $env:GIT_TERMINAL_PROMPT = "0"
    $out = & git -C $JailbreaksDir pull --ff-only 2>&1
    $code = $LASTEXITCODE
    $text = ($out -join " ")
    if ($code -ne 0) {
        return ("failed: " + (($out | Select-Object -First 1) -join " "))
    }
    if ($text -match 'Already up.to.date|Already up-to-date') { return "up-to-date" }
    return "updated"
}

function Get-SessionModel {
    $sid = $env:OPENCODE_SESSION_ID
    if (-not $sid) { throw "OPENCODE_SESSION_ID is not set and -Model was not given." }
    $raw = & opencode api get "/api/session/$sid" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $raw) { throw "opencode api could not read session $sid." }
    $payload = $raw | ConvertFrom-Json
    if (-not $payload.data -or -not $payload.data.model) {
        throw "session $sid has no model in its payload."
    }
    return [PSCustomObject]@{
        Model    = [string]$payload.data.model.id
        Provider = [string]$payload.data.model.providerID
    }
}

# ---------------------------------------------------------------- main

if ($List) {
    $available = Get-AvailableFiles
    if ($Json) {
        [PSCustomObject]@{
            status    = 'list'
            available = @($available | ForEach-Object { [PSCustomObject]@{ label = $_.Label; file = $_.File } })
        } | ConvertTo-Json -Depth 5
        exit 0
    }
    Write-Output "STATUS=list"
    Write-Output "AVAILABLE:"
    foreach ($i in $available) { Write-Output ("- " + $i.Label + " -> " + $i.File) }
    exit 0
}

if (-not $Model) {
    $session = Get-SessionModel
    $Model = $session.Model
    if (-not $Provider) { $Provider = $session.Provider }
}
if ($Model -match '#') { $Model = $Model -replace '#.*$', '' }
if ($Model -match '^([^/]+)/(.+)$') {
    if (-not $Provider) { $Provider = $Matches[1] }
    $Model = $Matches[2]
}
if (-not $Provider) { $Provider = "unknown" }

$hit = Resolve-Match $Model $Provider
$pull = "not-needed"

if (-not $hit -and -not $NoPull) {
    $pull = Update-Repo
    $hit = Resolve-Match $Model $Provider
}

$available = Get-AvailableFiles

if ($Json) {
    $result = [PSCustomObject]@{
        model     = $Model
        provider  = $Provider
        status    = $(if ($hit) { 'matched' } else { 'no-match' })
        file      = $(if ($hit) { (Join-Path $JailbreaksDir $hit.File) } else { $null })
        label     = $(if ($hit) { $hit.Label } else { $null })
        source    = $(if ($hit) { $hit.Source } else { $null })
        pull      = $pull
        available = @($available | ForEach-Object { [PSCustomObject]@{ label = $_.Label; file = $_.File } })
    }
    $result | ConvertTo-Json -Depth 5
    exit 0
}

Write-Output ("MODEL=" + $Model)
Write-Output ("PROVIDER=" + $Provider)
if ($hit) {
    Write-Output "STATUS=matched"
    Write-Output ("FILE=" + (Join-Path $JailbreaksDir $hit.File))
    Write-Output ("LABEL=" + $hit.Label)
    Write-Output ("SOURCE=" + $hit.Source)
    Write-Output ("PULL=" + $pull)
} else {
    Write-Output "STATUS=no-match"
    Write-Output ("FILE=")
    Write-Output ("PULL=" + $pull)
    Write-Output "AVAILABLE:"
    foreach ($i in $available) { Write-Output ("- " + $i.Label + " -> " + $i.File) }
}
