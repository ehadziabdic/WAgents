# tg-send.ps1 - send a Telegram message as the bot (for the main agent's own use).
# Reads credentials from scripts/.telegram.env. Usage:
#   tg-send.ps1 -Text "hello"
#   tg-send.ps1 -Text "caption" -File "C:\path\doc.pdf"  (sendDocument)
param([string]$Text = "", [string]$File = "")
$pairs = @{}
Get-Content (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".telegram.env") |
  Where-Object { $_ -match "=" } | ForEach-Object {
    $kv = $_ -split "=", 2; $pairs[$kv[0].Trim()] = $kv[1].Trim()
  }
$tok = $pairs["OPENCODE_TELEGRAM_TOKEN"]; $cid = $pairs["TELEGRAM_ALLOWED_CHAT_ID"]
if (-not $tok -or -not $cid) { Write-Host "TG-NO-CREDS"; exit 1 }
if ($Text.Length -gt 4000) { $Text = $Text.Substring(0, 4000) }
if ($File) {
  if (-not (Test-Path $File)) { Write-Host "TG-NO-FILE"; exit 1 }
  Add-Type -AssemblyName System.Net.Http
  $c = New-Object System.Net.Http.HttpClient
  try {
    $mp = New-Object System.Net.Http.MultipartFormDataContent
    $mp.Add((New-Object System.Net.Http.StringContent($cid)), "chat_id")
    if ($Text) { $mp.Add((New-Object System.Net.Http.StringContent($Text)), "caption") }
    $fs = [System.IO.File]::OpenRead($File)
    $fc = New-Object System.Net.Http.StreamContent($fs)
    $fc.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/pdf")
    $mp.Add($fc, "document", [System.IO.Path]::GetFileName($File))
    $resp = $c.PostAsync("https://api.telegram.org/bot$tok/sendDocument", $mp).Result
    $fs.Close()
    Write-Host ("TG-FILE-SENT:" + $resp.IsSuccessStatusCode)
    if (-not $resp.IsSuccessStatusCode) { exit 1 }
  } finally { $c.Dispose() }
  exit 0
}
$r = Invoke-RestMethod "https://api.telegram.org/bot$tok/sendMessage" -Method Post -Body @{chat_id = $cid; text = $Text} -TimeoutSec 20
Write-Host ("TG-SENT:" + $r.ok)
