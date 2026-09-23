#Requires -RunAsAdministrator
# WAgents installer: overlays this repo onto a fresh Windows machine.
# Run AFTER Phase 0 of docs/AGENT-SETUP-PROMPT.md (OpenCode installed once).
# Public edition: ships ZERO secrets. Every secret step prints exactly
# what to paste and where; the agent collects them in one ask.
$ErrorActionPreference = "Stop"
$Repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$Config = Join-Path $env:USERPROFILE ".config\opencode"
$Share = Join-Path $env:USERPROFILE ".local\share\opencode"

Write-Host "[0/9] Base tools (best effort, continue on failure)..."
foreach ($p in @("Tailscale.Tailscale", "Python.Python.3.13", "OpenJS.NodeJS.LTS", "Git.Git")) {
  try { winget install $p --accept-source-agreements --accept-package-agreements --silent } catch { Write-Host ("  skip: " + $p) }
}

Write-Host "[1/9] Config overlay (no secrets in repo)..."
New-Item -ItemType Directory -Force -Path $Config | Out-Null
robocopy "$Repo\opencode" $Config /E /XD node_modules __pycache__ .out .brave-debug-profile /XF *.bak | Out-Null

Write-Host "[2/9] Service password..."
Write-Host "  Set a long random password in $Config\service.json (field: password)."

Write-Host "[3/9] Firewall: opencode Private-only..."
opencode session list | Out-Null
Start-Sleep 3
Get-NetFirewallRule -DisplayName "opencode*" -ErrorAction SilentlyContinue | Set-NetFirewallRule -Profile Private
Get-NetFirewallRule -DisplayName "opencode*" | Select-Object DisplayName, Profile | Format-Table -AutoSize | Out-String -Width 120 | Write-Host

Write-Host "[4/9] rclone (Drive)..."
winget install Rclone.Rclone --accept-source-agreements --accept-package-agreements
Write-Host "  Then: rclone config (new remote 'gdrive', Google Drive, own client_id),"
Write-Host "  or copy an existing %APPDATA%\rclone\rclone.conf."

Write-Host "[5/9] Provider keys..."
Write-Host "  opencode auth login (repeat per account), or place auth.json in $Share."
Write-Host "  Figma: put your Bearer token in opencode.jsonc (figma-mcp headers)."

Write-Host "[6/9] Node deps..."
Push-Location "$Repo\opencode"; npm install; Pop-Location
Push-Location "$Repo\opencode\skills\drawio\scripts"; npm install; Pop-Location

Write-Host "[7/9] Python deps + whisper model..."
pip install -r "$Repo\telegram\requirements.txt"
python -c "from faster_whisper import WhisperModel; WhisperModel('small', device='cpu', compute_type='int8'); print('whisper-small ready')"

Write-Host "[8/9] Telegram bot identity..."
Write-Host "  Create bot via @BotFather, chat ID via @userinfobot, write both"
Write-Host "  into telegram/.telegram.env (see .telegram.env.example), then copy"
Write-Host "  the telegram/ folder env files into place. Start bot per README."

Write-Host "[9/9] Done. Manual steps in docs/SETUP.md section 2:"
Write-Host "  - Tailscale login + machine approval + Private check,"
Write-Host "    Brave debug relaunch, JupyterHub token, Telegram bot start."
