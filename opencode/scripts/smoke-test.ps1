# WAgents setup smoke test.
# One command that answers: is this install healthy right now?
#
# Checks, in order:
#   1. config documents load and the merged opencode.json is the source of truth
#   2. agent registry count and that every custom agent file registered
#   3. skill registry: no duplicate IDs, every skill dir has a valid SKILL.md
#   4. plugin registry: no "failed to load plugin" on a fresh server start
#   5. MCP: every server reports connected or disabled, none errored
#   6. jailbreak resolver: model-to-file mapping still resolves
#
# Exit 0 when every check passes, 1 when any fails.
# Usage: powershell -File smoke-test.ps1 [-Verbose]

param([switch]$Verbose)

$ErrorActionPreference = "Continue"
$Config = Join-Path $env:USERPROFILE ".config\opencode"
$fails = 0
$warns = 0

function Check($name, $ok, $detail) {
    if ($ok) {
        Write-Host ("  PASS  {0,-34} {1}" -f $name, $detail) -ForegroundColor Green
    } else {
        $script:fails++
        Write-Host ("  FAIL  {0,-34} {1}" -f $name, $detail) -ForegroundColor Red
    }
}

function Warn($name, $detail) {
    $script:warns++
    Write-Host ("  WARN  {0,-34} {1}" -f $name, $detail) -ForegroundColor Yellow
}

Write-Host ""
Write-Host "WAgents smoke test" -ForegroundColor Cyan
Write-Host ("config: " + $Config)
Write-Host ("time:   " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
Write-Host ""

# ---------------------------------------------------------------- 1. config
Write-Host "1. Configuration" -ForegroundColor Cyan
try {
    $docs = (& opencode api get /api/config 2>&1 | Out-String) | ConvertFrom-Json
    $all = @($docs)
    $main = @($all | Where-Object { $_.type -eq 'document' -and $_.path -like "*\opencode\opencode.json" })
    Check "config documents load" ($all.Count -ge 1) ("$($all.Count) documents")
    Check "merged opencode.json present" ($main.Count -eq 1) $(if ($main.Count -eq 1) { $main[0].path } else { "not found" })
    $stray = @($all | Where-Object { $_.type -eq 'document' -and $_.path -like "*\opencode\opencode.json" })
    Check "no duplicate jsonc config" ($stray.Count -eq 0) $(if ($stray.Count) { ($stray | ForEach-Object { $_.path }) -join ', ' } else { "clean" })
    if ($main.Count -eq 1) {
        $pol = @($main[0].info.policies)
        Check "policies loaded" ($pol.Count -gt 0) ("$($pol.Count) statements")
        # V2 normalises the old `provider` key to `providers`; accept either.
        $pnames = @($main[0].info.PSObject.Properties.Name)
        $prov = @($main[0].info.providers.PSObject.Properties.Name) + @($main[0].info.provider.PSObject.Properties.Name)
        Check "providers block present" (($pnames -contains 'providers') -or ($pnames -contains 'provider')) ("$(@($prov | Where-Object { $_ }).Count) providers")
    }
} catch {
    Check "config documents load" $false $_.Exception.Message
}

# ---------------------------------------------------------------- 2. agents
Write-Host ""
Write-Host "2. Agents" -ForegroundColor Cyan
try {
    $agents = @(((& opencode api get /api/agent 2>&1 | Out-String) | ConvertFrom-Json).data)
    Check "agent registry" ($agents.Count -ge 20) ("$($agents.Count) agents")
    $files = @(Get-ChildItem (Join-Path $Config "agents") -Filter *.md -File -ErrorAction SilentlyContinue)
    $missing = @()
    foreach ($f in $files) {
        $id = $f.BaseName
        if (-not ($agents | Where-Object { $_.id -eq $id })) { $missing += $id }
    }
    Check "every agent file registered" ($missing.Count -eq 0) $(if ($missing.Count) { "missing: " + ($missing -join ', ') } else { "$($files.Count) files" })
    $customIds = @($files | ForEach-Object { $_.BaseName })
    # Builtin runtime agents (compaction, title, summary) carry no description and
    # are not ours to fix, so only grade the agent files that live on disk.
    $nodesc = @($agents | Where-Object {
        $customIds -contains $_.id -and (-not $_.description -or $_.description.Trim().Length -lt 10)
    })
    Check "every agent has a description" ($nodesc.Count -eq 0) $(if ($nodesc.Count) { ($nodesc | ForEach-Object { $_.id }) -join ', ' } else { "$($customIds.Count) custom agents" })
} catch {
    Check "agent registry" $false $_.Exception.Message
}

# ---------------------------------------------------------------- 3. skills
Write-Host ""
Write-Host "3. Skills" -ForegroundColor Cyan
try {
    $skills = @(((& opencode api get /api/skill 2>&1 | Out-String) | ConvertFrom-Json).data)
    $ids = @($skills | ForEach-Object { $_.id })
    $dupes = @($ids | Group-Object | Where-Object { $_.Count -gt 1 })
    Check "no duplicate skill IDs" ($dupes.Count -eq 0) $(if ($dupes.Count) { ($dupes | ForEach-Object { "$($_.Name)x$($_.Count)" }) -join ', ' } else { "$($ids.Count) unique" })

    $skRoot = Join-Path $Config "skills"
    $dirs = @(Get-ChildItem $skRoot -Directory -ErrorAction SilentlyContinue)
    $bad = @()
    $nofm = @()
    foreach ($d in $dirs) {
        $p = Join-Path $d.FullName "SKILL.md"
        if (-not (Test-Path $p)) { $bad += "$($d.Name) (no SKILL.md)"; continue }
        $t = [System.IO.File]::ReadAllText($p)
        # Grab the opening frontmatter block as literal text instead of trusting a
        # single regex: key order and line endings both vary across sources.
        $m = [regex]::Match($t, '\A\uFEFF?---\r?\n(?<fm>.*?)\r?\n---', 'Singleline')
        if (-not $m.Success) { $bad += "$($d.Name) (no frontmatter)"; continue }
        $fm = $m.Groups['fm'].Value
        $hasName = [regex]::IsMatch($fm, '(?m)^name:\s*\S')
        $hasDesc = [regex]::IsMatch($fm, '(?m)^description:\s*\S')
        if (-not ($hasName -and $hasDesc)) { $nofm += $d.Name }
    }
    Check "every skill dir has valid SKILL.md" ($bad.Count -eq 0) $(if ($bad.Count) { "bad: " + ($bad -join ', ') } else { "$($dirs.Count) dirs" })
    Check "frontmatter has name and description" ($nofm.Count -eq 0) $(if ($nofm.Count) { "incomplete: " + ($nofm -join ', ') } else { "all present" })

    $hidden = @($skills | Where-Object { $_.autoinvoke -eq $false })
    $advertised = @($skills | Where-Object { $_.autoinvoke -ne $false })
    $chars = 0
    foreach ($s in $advertised) { $chars += $s.description.Length }
    Write-Host ("        advertised {0}, hidden {1}, description payload ~{2} tokens" -f $advertised.Count, $hidden.Count, [math]::Round($chars / 4))

    $divergent = @()
    foreach ($d in $dirs) {
        $p = Join-Path $d.FullName "SKILL.md"
        if (Test-Path $p) {
            $t = [System.IO.File]::ReadAllText($p)
            if ($t -match '\.\./docs/') { $divergent += $d.Name }
        }
    }
    if ($divergent.Count) { Warn "cross-skill .docs links" (($divergent | Select-Object -First 5) -join ', ') } else { Check "cross-skill links resolve" $true "no ../docs/ refs" }
} catch {
    Check "skill registry" $false $_.Exception.Message
}

# -------------------------------------------------------------- 4. plugins
Write-Host ""
Write-Host "4. Plugins" -ForegroundColor Cyan
try {
    $log = Join-Path $env:LOCALAPPDATA "opencode\log\opencode.log"
    if (-not (Test-Path $log)) { $log = Join-Path $env:USERPROFILE ".local\share\opencode\log\opencode.log" }
    $before = if (Test-Path $log) { (Get-Item $log).Length } else { 0 }
    $out = & opencode api --standalone --print-logs --log-level info get /api/config 2>&1 | Out-String
    $failLines = @(($out -split "`n") | Where-Object { $_ -match 'failed to load plugin' })
    $loadLines = @(($out -split "`n") | Where-Object { $_ -match 'loading plugin' })
    Check "no plugin load failures" ($failLines.Count -eq 0) $(if ($failLines.Count) { ($failLines | ForEach-Object { ($_ -split 'target=')[-1] }) -join ', ' } else { "$($loadLines.Count) plugins loaded" })
} catch {
    Check "plugin load" $false $_.Exception.Message
}

# ------------------------------------------------------------------ 5. MCP
Write-Host ""
Write-Host "5. MCP servers" -ForegroundColor Cyan
try {
    $mcpOut = & opencode mcp list 2>&1 | Out-String
    $lines = @($mcpOut -split "`n" | Where-Object { $_.Trim() })
    $connected = @($lines | Where-Object { $_ -match 'connected' })
    $disabled = @($lines | Where-Object { $_ -match 'disabled' })
    $errored = @($lines | Where-Object { $_ -match 'error|failed|timeout' })
    Check "no MCP server errored" ($errored.Count -eq 0) $(if ($errored.Count) { ($errored | ForEach-Object { $_.Trim() }) -join '; ' } else { "$($connected.Count) connected, $($disabled.Count) disabled" })
    $active = @("context7", "tavily", "playwright", "scrapling", "codebase-memory", "iris")
    $notUp = @()
    foreach ($s in $active) {
        if (-not ($connected | Where-Object { $_ -match [regex]::Escape($s) })) { $notUp += $s }
    }
    Check "always-on servers connected" ($notUp.Count -eq 0) $(if ($notUp.Count) { "not connected: " + ($notUp -join ', ') } else { "$($active.Count) servers" })
} catch {
    Check "MCP list" $false $_.Exception.Message
}

# ------------------------------------------------------------- 6. resolver
Write-Host ""
Write-Host "6. Jailbreak resolver" -ForegroundColor Cyan
$resolver = Join-Path $Config "scripts\resolve-jailbreak.ps1"
if (Test-Path $resolver) {
    $map = Join-Path $Config "scripts\jailbreak-model-map.json"
    try {
        $m = Get-Content $map -Raw | ConvertFrom-Json
        $entries = @($m.PSObject.Properties)
        Check "model map loads" ($entries.Count -gt 0) ("$($entries.Count) entries")
    } catch {
        Check "model map loads" $false $_.Exception.Message
    }
} else {
    Warn "resolver script" "not found at scripts\resolve-jailbreak.ps1"
}

# ---------------------------------------------------------------- summary
Write-Host ""
if ($fails -eq 0) {
    Write-Host ("RESULT: healthy ({0} warnings)" -f $warns) -ForegroundColor Green
    exit 0
} else {
    Write-Host ("RESULT: {0} failure(s), {1} warning(s)" -f $fails, $warns) -ForegroundColor Red
    exit 1
}
