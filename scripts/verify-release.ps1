# verify-release.ps1 - release gate for WAgents. Fails (exit 1) on any problem.
$ErrorActionPreference = "Stop"
$Repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$fail = 0
function Fail($msg) { Write-Host ("FAIL: " + $msg); $script:fail = 1 }

# 1. Required files
foreach ($f in @("README.md","LICENSE","SECURITY.md","VERSION","CHANGELOG.md","package.json","install.ps1","AGENTS.md",".claude-plugin/plugin.json",".claude-plugin/marketplace.json","pictures/logo.png","pictures/banner.png",".github/FUNDING.yml")) {
  if (-not (Test-Path -LiteralPath (Join-Path $Repo $f))) { Fail ("missing " + $f) }
}

# 2. Version consistency
$ver = (Get-Content -LiteralPath (Join-Path $Repo "VERSION") -Raw).Trim()
foreach ($p in @("package.json", ".claude-plugin/plugin.json", ".claude-plugin/marketplace.json")) {
  $t = Get-Content -LiteralPath (Join-Path $Repo $p) -Raw
  if ($t -notmatch [regex]::Escape($ver)) { Fail ("version mismatch in " + $p) }
}

# 3. Skill hygiene: every skill dir has SKILL.md with matching name.
# devops-docs is templates-only by design; scientific-* is the vendored
# K-Dense set, kept upstream-verbatim including upstream short names.
Get-ChildItem -LiteralPath (Join-Path $Repo "opencode/skills") -Directory | Where-Object { $_.Name -ne "devops-docs" -and $_.Name -notlike "scientific-*" } | ForEach-Object {
  $sk = Join-Path $_.FullName "SKILL.md"
  if (-not (Test-Path -LiteralPath $sk)) { Fail ("no SKILL.md in " + $_.Name); return }
  $head = (Get-Content -LiteralPath $sk -TotalCount 5) -join "`n"
  if ($head -notmatch ("name:\s*[`"']?" + [regex]::Escape($_.Name))) { Fail ("name mismatch in " + $_.Name) }
}

# 4. Main agent files present
foreach ($a in @("opencode/agents/[WAgent] Build.md","opencode/agents/[WAgent] Plan.md","opencode/agents/[WAgent] Unrestricted.md")) {
  if (-not (Test-Path -LiteralPath (Join-Path $Repo $a))) { Fail ("missing " + $a) }
}

# 4b. Hard exclusions: PII and the separate prompt collection never ship public.
foreach ($banned in @("opencode/aboutme.md", "opencode/jailbreaks")) {
  if (Test-Path -LiteralPath (Join-Path $Repo $banned)) { Fail ("banned path present: " + $banned) }
}

# 5. Secret sweep over config, docs, agents, and scripts (skills excluded:
# vendored examples contain fake keys by design).
$scanRoots = @("opencode", "local-share", "telegram", "rclone", "docs", "AGENTS.md", "README.md", "SECURITY.md", "install.ps1", "import-credentials.ps1")
$files = foreach ($r in $scanRoots) {
  $p = Join-Path $Repo $r
  if (Test-Path -LiteralPath $p -PathType Container) {
    Get-ChildItem -LiteralPath $p -Recurse -File -ErrorAction SilentlyContinue
  } elseif (Test-Path -LiteralPath $p) {
    Get-Item -LiteralPath $p
  }
}
$files = $files | Where-Object { $_.FullName -notmatch '\\skills\\' -and $_.Extension -in @(".md",".json",".jsonc",".ps1",".py",".js",".mjs",".cjs",".txt",".yml",".yaml",".env",".conf",".example",".toml") }

$patterns = @(
  "-----BEGIN [A-Z ]*PRIVATE KEY-----",
  "vck_[A-Za-z0-9]{20,}",
  "ctx7sk-[A-Za-z0-9-]{10,}",
  "ghp_[A-Za-z0-9]{20,}",
  "oc_sk_[A-Za-z0-9_-]{20,}",
  "nvapi-[A-Za-z0-9_-]{20,}",
  "tvly-[A-Za-z0-9-]{20,}",
  "sntryu_[A-Za-z0-9]{20,}",
  "figu_[A-Za-z0-9_-]{10,}",
  "ya29\.[0-9A-Za-z_-]{20,}",
  "\b\d{7,10}:[A-Za-z0-9_-]{30,}",
  "AIza[0-9A-Za-z_-]{30,}",
  "sk-or-v1-[A-Za-z0-9]{20,}",
  "hf_oauth_[A-Za-z0-9_-]{10,}",
  "pat[A-Za-z0-9]{10,}\.[0-9a-f]{20,}",
  "\bsk-[A-Za-z0-9]{20,}"
)
$hits = $files | Select-String -Pattern $patterns -ErrorAction SilentlyContinue |
  Where-Object { $_.Line -notmatch "REPLACE_ME|PUT-YOUR|CHANGE-ME|example|your_|your-|\.\.\.|<|\\u003c" }
foreach ($h in $hits) { Fail ("possible secret " + $h.Path + ":" + $h.LineNumber) }

# 5b. Password fields must be placeholders.
$svc = Join-Path $Repo "opencode/service.json"
if (Test-Path -LiteralPath $svc) {
  $pw = (Get-Content -LiteralPath $svc -Raw | ConvertFrom-Json).password
  if ($pw -and $pw -notin @("CHANGE-ME", "REPLACE_ME")) { Fail ("service.json password is not a placeholder") }
}

if ($fail -eq 0) { Write-Host "VERIFY-RELEASE: PASS" } else { Write-Host "VERIFY-RELEASE: HOLD" }
exit $fail
