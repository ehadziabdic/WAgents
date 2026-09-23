# Main-profile Brave debug launcher.
# Requires ONE restart of Brave with the flag. Close Brave once, run this, your tabs/session are kept (same User Data).
$brave = "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"
$dataDir = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
$already = Test-NetConnection -ComputerName 127.0.0.1 -Port 9333 -WarningAction SilentlyContinue
if ($already.TcpTestSucceeded) { Write-Host "ALREADY-OPEN 9333"; exit 0 }
Start-Process $brave -ArgumentList "--remote-debugging-port=9333 --user-data-dir=`"$dataDir`""
Start-Sleep 2
Test-NetConnection -ComputerName 127.0.0.1 -Port 9333 | Select-Object TcpTestSucceeded
