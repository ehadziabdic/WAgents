$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
@("screenshot-desktop.ps1","focus-window.ps1","gpu-status.ps1","tail-log.ps1","cleanup-out.ps1") | ForEach-Object {
  if (-not (Test-Path (Join-Path $root $_))) { throw "missing $_" }
}
& (Join-Path $root "screenshot-desktop.ps1") -OutDir (Join-Path $root ".out")
$png = Get-ChildItem (Join-Path $root ".out/*.png") | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $png -or $png.Length -lt 5000) { throw "screenshot failed or too small" }
Write-Host "TASK1-OK $($png.FullName)"
