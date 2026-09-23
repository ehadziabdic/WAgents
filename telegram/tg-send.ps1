# tg-send.ps1 - send a Telegram message as the bot (for the main agent's own use).
# Reads credentials from scripts/.telegram.env. Usage: tg-send.ps1 -Text "hello"
param([string]$Text = "")
$pairs = @{}
Get-Content (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".telegram.env") |
  Where-Object { $_ -match "=" } | ForEach-Object {
    $kv = $_ -split "=", 2; $pairs[$kv[0].Trim()] = $kv[1].Trim()
  }
$tok = $pairs["OPENCODE_TELEGRAM_TOKEN"]; $cid = $pairs["TELEGRAM_ALLOWED_CHAT_ID"]
if (-not $tok -or -not $cid) { Write-Host "TG-NO-CREDS"; exit 1 }
if ($Text.Length -gt 4000) { $Text = $Text.Substring(0, 4000) }
$r = Invoke-RestMethod "https://api.telegram.org/bot$tok/sendMessage" -Method Post -Body @{chat_id = $cid; text = $Text} -TimeoutSec 20
Write-Host ("TG-SENT:" + $r.ok)
