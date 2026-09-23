param([string]$LogPath, [string]$DonePattern = "Training complete", [string]$Watch = "")
if ($Watch -ne "" -and (Test-Path $Watch)) {
  $w = Get-Content $Watch -Raw | ConvertFrom-Json
  $LogPath = $w.logPath; $DonePattern = $w.donePattern
}
if (-not (Test-Path $LogPath)) { Write-Host "NOT-DONE NO-LOG:$LogPath"; exit 0 }
$tail = Get-Content $LogPath -Tail 30
if ($tail -match $DonePattern) { Write-Host "DONE $DonePattern"; } else { Write-Host "NOT-DONE last: $($tail[-1])" }
