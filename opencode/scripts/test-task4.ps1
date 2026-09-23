$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not (Test-Path (Join-Path $root "telegram-pc-bot.py"))) { throw "missing telegram-pc-bot.py" }
if (-not (Test-Path (Join-Path $root ".telegram.env.example"))) { throw "missing .telegram.env.example" }
python -m py_compile (Join-Path $root "telegram-pc-bot.py")
if ($LASTEXITCODE -ne 0) { throw "py_compile failed" }
Write-Host "TASK4-OK (needs BOT_TOKEN + CHAT_ID for live test)"
