param([string]$OutDir = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".out"), [int]$MaxAgeMinutes = 10)
if (-not (Test-Path $OutDir)) { exit 0 }
Get-ChildItem "$OutDir/*.png" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddMinutes(-$MaxAgeMinutes) } | Remove-Item -Force -ErrorAction SilentlyContinue
Write-Host "CLEANED"
