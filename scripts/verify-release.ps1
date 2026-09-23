# verify-release.ps1 - release gate for WAgents. Fails (exit 1) on any problem.
$ErrorActionPreference = "Stop"
$Repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$fail = 0
function Fail($msg) { Write-Host ("FAIL: " + $msg); $script:fail = 1 }

# 1. Required files
foreach ($f in @("README.md","LICENSE","SECURITY.md","VERSION","CHANGELOG.md","package.json","install.ps1","AGENTS.md",".claude-plugin/plugin.json",".claude-plugin/marketplace.json","pictures/logo.png","pictures/banner.png",".github/FUNDING.yml")) {
  if (-not (Test-Path (Join-Path $Repo $f))) { Fail ("missing " + $f) }
}

# 2. Version consistency
$ver = (Get-Content (Join-Path $Repo "VERSION") -Raw).Trim()
foreach ($p in @("package.json", ".claude-plugin/plugin.json", ".claude-plugin/marketplace.json")) {
  $t = Get-Content -Raw (Join-Path $Repo $p)
  if ($t -notmatch [regex]::Escape($ver)) { Fail ("version mismatch in " + $p) }
}

# 3. Skill hygiene: every skill dir has SKILL.md with matching name
# (devops-docs is templates-only by design, not a skill).
Get-ChildItem (Join-Path $Repo "opencode/skills") -Directory | Where-Object { $_.Name -ne "devops-docs" } | ForEach-Object {
  $sk = Join-Path $_.FullName "SKILL.md"
  if (-not (Test-Path $sk)) { Fail ("no SKILL.md in " + $_.Name); return }
  $head = (Get-Content $sk -TotalCount 5) -join "`n"
  if ($head -notmatch ("name: " + $_.Name)) { Fail ("name mismatch in " + $_.Name) }
}

# 4. Agent files present
foreach ($a in @("opencode/agents/wagent.md","opencode/agents/wagent-ask.md","opencode/agents/wagent-hacker.md")) {
  if (-not (Test-Path (Join-Path $Repo $a))) { Fail ("missing " + $a) }
}

# 5. Secret sweep (tight patterns: values, not doc examples)
$hits = Get-ChildItem (Join-Path $Repo "opencode"), (Join-Path $Repo "telegram"), (Join-Path $Repo "local-share"), (Join-Path $Repo "rclone"), (Join-Path $Repo "docs"), (Join-Path $Repo "install.ps1") -Recurse -File -ErrorAction SilentlyContinue |
  Select-String -Pattern "ya29\.|vck_[A-Za-z0-9]{10,}|figu_[A-Za-z0-9_-]{10,}|AAFrF|sk-ant-[A-Za-z0-9_-]{10,}|AIza[0-9A-Za-z\-_]{20,}|1//0[0-9A-Za-z_-]{10,}|tvly-d[A-Za-z0-9]+|sntryu_[A-Za-z0-9]+|ghp_[A-Za-z0-9]+|xox[bap]-[A-Za-z0-9-]+" -ErrorAction SilentlyContinue |
  Where-Object { $_.Line -notmatch "sk-ant-admin\.\.\.|PUT-YOUR|TOKENHERE|_xxx|xxx_|\.\.\.|example|your_|shapes" }
foreach ($h in $hits) { Fail ("possible secret " + $h.Path + ":" + $h.LineNumber) }

if ($fail -eq 0) { Write-Host "VERIFY-RELEASE: PASS" } else { Write-Host "VERIFY-RELEASE: HOLD" }
exit $fail
