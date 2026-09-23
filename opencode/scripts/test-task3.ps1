$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
"epoch 49/50 loss 0.12" | Out-File (Join-Path $root ".out/dummy-train.log") -Encoding utf8
"Training complete epoch 50/50" | Out-File (Join-Path $root ".out/dummy-train-done.log") -Encoding utf8
if (-not (Test-Path (Join-Path $root "check-training.ps1"))) { throw "missing check-training.ps1" }
$r1 = & (Join-Path $root "check-training.ps1") -LogPath (Join-Path $root ".out/dummy-train.log") -DonePattern "Training complete"
if ($r1 -notmatch "NOT-DONE") { throw "expected NOT-DONE got $r1" }
$r2 = & (Join-Path $root "check-training.ps1") -LogPath (Join-Path $root ".out/dummy-train-done.log") -DonePattern "Training complete"
if ($r2 -notmatch "DONE") { throw "expected DONE got $r2" }
Write-Host "TASK3-OK"
