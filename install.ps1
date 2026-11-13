#Requires -RunAsAdministrator
# WAgents installer: overlays this repo onto a fresh Windows machine.
# Run AFTER Phase 0 of docs/AGENT-SETUP-PROMPT.md (OpenCode installed once).
# This public repo ships placeholders, not live credentials. Fill the
# placeholder files first, or let `opencode auth login` create them after
# the first launch.
param(
  [string]$JailbreaksRepo = ""
)
$ErrorActionPreference = "Stop"
$Repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$Config = Join-Path $env:USERPROFILE ".config\opencode"
$Share = Join-Path $env:USERPROFILE ".local\share\opencode"

Write-Host "[0/10] Base tools (best effort, continue on failure)..."
foreach ($p in @("Tailscale.Tailscale", "Python.Python.3.13", "OpenJS.NodeJS.LTS", "Git.Git", "BraveSoftware.BraveBrowser")) {
  try { winget install $p --accept-source-agreements --accept-package-agreements --silent } catch { Write-Host ("  skip: " + $p) }
}

Write-Host "[1/10] Config overlay..."
New-Item -ItemType Directory -Force -Path $Config | Out-Null
foreach ($f in @("opencode.json","service.json")) {
  $existing = Join-Path $Config $f
  if (Test-Path -LiteralPath $existing) { Copy-Item -LiteralPath $existing -Destination ($existing + ".bak") -Force }
}
robocopy "$Repo\opencode" $Config /E /XD node_modules __pycache__ .out .brave-debug-profile /XF *.bak | Out-Null

Write-Host "[2/10] Local share templates..."
New-Item -ItemType Directory -Force -Path $Share | Out-Null
Get-ChildItem -LiteralPath "$Repo\local-share" -File -Filter *.json | ForEach-Object {
  $dest = Join-Path $Share $_.Name
  if (-not (Test-Path -LiteralPath $dest)) { Copy-Item -LiteralPath $_.FullName -Destination $dest }
}

Write-Host "[3/10] Firewall: opencode Private-only..."
opencode session list | Out-Null
Start-Sleep 3
Get-NetFirewallRule -DisplayName "opencode*" -ErrorAction SilentlyContinue | Set-NetFirewallRule -Profile Private
Get-NetFirewallRule -DisplayName "opencode*" | Select-Object DisplayName, Profile | Format-Table -AutoSize | Out-String -Width 120 | Write-Host

Write-Host "[4/10] rclone config..."
New-Item -ItemType Directory -Force -Path "$env:APPDATA\rclone" | Out-Null
$rcloneDest = "$env:APPDATA\rclone\rclone.conf"
if (-not (Test-Path -LiteralPath $rcloneDest)) { Copy-Item -LiteralPath "$Repo\rclone\rclone.conf" -Destination $rcloneDest }

Write-Host "[5/10] Node deps..."
Push-Location "$Repo\opencode"; npm install; Pop-Location
Push-Location "$Repo\opencode\skills\drawio\scripts"; npm install; Pop-Location

Write-Host "[5b/10] Harness scanner warmup (cached, no install)..."
npx -y harness-score --version

Write-Host "[5c/10] MCP warmup (npx caches, no prompts)..."
npx -y @playwright/mcp@0.0.83 --version
npx -y rea-agents@6.7.0 --version
Write-Host "  Remote MCPs use OAuth: run 'opencode mcp auth 21st' once (design),"
Write-Host "  plus any of airtable/figma/notion/huggingface/sentry/github you use."

Write-Host "[5d/10] OpenCode Browse (Brave agent driver) (best effort)..."
# Installs browse.exe to ~/.local/bin, verifies its SHA-256, and wires the
# 'browse' MCP server into opencode.json. A Brave window will open on the
# Chrome Web Store page: click 'Add to Brave' once, keep Brave open, and the
# installer finishes pairing automatically (it waits, then gives up quietly).
# After this step, Brave keeps agent tabs in background groups with your
# logins, and can hand 2FA/payment steps back to you.
try {
  & ([scriptblock]::Create((irm "https://opencode.ai/browse/install.ps1"))) --agent opencode
  Write-Host "  Browse installed and wired into opencode.json."
} catch {
  Write-Host "  Browse install skipped/failed: $($_.Exception.Message)"
  Write-Host "  Safe to re-run later (or run browse install by hand)."
}

Write-Host "[5e/10] Jailbreak prompt collection (optional)..."
# [WAgent] Unrestricted resolves exactly one prompt file per model from
# %USERPROFILE%\.config\opencode\jailbreaks. That collection is a separate
# repository on purpose and is not shipped in this repo.
$JailbreaksDir = Join-Path $Config "jailbreaks"
$jbCount = 0
if (Test-Path -LiteralPath $JailbreaksDir) {
  $jbCount = (Get-ChildItem -LiteralPath $JailbreaksDir -File -Filter *.md -ErrorAction SilentlyContinue | Measure-Object).Count
}
if ($jbCount -gt 0) {
  Write-Host "  Found $jbCount prompt files in $JailbreaksDir, left untouched."
} elseif ($JailbreaksRepo) {
  if (Test-Path -LiteralPath (Join-Path $JailbreaksDir ".git")) {
    Write-Host "  Existing checkout kept. Update with: git -C `"$JailbreaksDir`" pull --ff-only"
  } else {
    git clone $JailbreaksRepo $JailbreaksDir
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath (Join-Path $JailbreaksDir ".git"))) {
      Write-Host "  Clone failed (git exit $LASTEXITCODE). Check the URL and your access."
      if ((Test-Path -LiteralPath $JailbreaksDir) -and -not (Get-ChildItem -LiteralPath $JailbreaksDir -Force -ErrorAction SilentlyContinue)) {
        Remove-Item -LiteralPath $JailbreaksDir -Force -ErrorAction SilentlyContinue
      }
    } else {
      Write-Host "  Cloned the prompt collection into $JailbreaksDir."
    }
  }
} else {
  Write-Host "  Not installed. [WAgent] Unrestricted reports STATUS=no-match until it is."
  Write-Host "  Re-run with the repository URL:"
  Write-Host "    .\install.ps1 -JailbreaksRepo <url>"
  Write-Host "  or clone by hand: git clone <url> `"$JailbreaksDir`""
  Write-Host "  The resolver and model map are already in place and need no setup."
}

Write-Host "[6/10] Python deps + whisper model..."
pip install -r "$Repo\telegram\requirements.txt"
python -c "from faster_whisper import WhisperModel; WhisperModel('small', device='cpu', compute_type='int8'); print('whisper-small ready')"

Write-Host "[7/10] rclone..."
winget install Rclone.Rclone --accept-source-agreements --accept-package-agreements

Write-Host "[8/10] Credentials (opencode accounts, MCP OAuth)..."
powershell -ExecutionPolicy Bypass -File "$Repo\import-credentials.ps1"

Write-Host "[9/10] Done. Manual steps in docs/SETUP.md section 2:"
Write-Host "  - Tailscale login + machine approval + Private check,"
Write-Host "    Brave debug relaunch, JupyterHub token, Telegram bot start,"
Write-Host "    Browse 'Add to Brave' click (opens itself)."
Write-Host "  - Note: Hex voice dictation is no longer installed automatically;"
Write-Host "    run the official installer by hand if you want it."
