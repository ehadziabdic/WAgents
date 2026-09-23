$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not (Test-Path (Join-Path $root "brave-debug-launch.ps1"))) { throw "missing brave-debug-launch.ps1" }
$tcp = Test-NetConnection -ComputerName 127.0.0.1 -Port 9333 -WarningAction SilentlyContinue
if (-not $tcp.TcpTestSucceeded) { throw "Brave debug port 9333 not open" }
Write-Host "TASK2-OK"
