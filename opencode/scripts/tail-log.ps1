param([string]$Path, [int]$Lines = 80)
if (-not $Path -or -not (Test-Path $Path)) { Write-Host "NO-LOG:$Path"; exit 1 }
Get-Content $Path -Tail $Lines
