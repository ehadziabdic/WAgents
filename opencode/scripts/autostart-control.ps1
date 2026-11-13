# autostart-control.ps1 - one switch for PC-side autostart daemons.
#
#   .\autostart-control.ps1 -Status    (default)
#   .\autostart-control.ps1 -Disable   pc boots quiet: no Telegram bot, no Hermes, no OmniRoute
#   .\autostart-control.ps1 -Enable    restore Telegram bot + Hermes + OmniRoute at login
#   .\autostart-control.ps1 -Enable -TelegramOnly    only the Telegram bot, keep the rest parked
#
# OpenChamber is never touched: it is the phone gateway and stays in
# HKCU Run with --background so the OpenCode server comes up with it.
#
# Nothing is deleted. Startup-folder entries are moved to scripts/parked-startup
# and moved back on -Enable. Older installs kept them in Startup\_disabled_autostart;
# that folder is migrated here automatically and removed, because Explorer kept
# reopening it at login.

param(
    [switch]$Enable,
    [switch]$Disable,
    [switch]$Status,
    [switch]$TelegramOnly
)

$ErrorActionPreference = "Stop"

$ConfigDir = Join-Path $env:USERPROFILE ".config\opencode"
$ScriptsDir = Join-Path $ConfigDir "scripts"
$StateFile = Join-Path $ScriptsDir ".autostart.json"
$PidFile = Join-Path $ScriptsDir ".telegram-bot.pid"
$BotPy = Join-Path $ScriptsDir "telegram-pc-bot.py"

$StartupDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
$LegacyDisabledDir = Join-Path $StartupDir "_disabled_autostart"
$DisabledDir = Join-Path $ScriptsDir "parked-startup"

# Startup-folder entries owned by this switch (OpenChamber is NOT here on purpose).
$ManagedEntries = @("Hermes_Gateway_wagent.vbs", "OmniRoute.lnk")

function Read-State {
    if (-not (Test-Path $StateFile)) {
        return [PSCustomObject]@{ telegramBot = $false; updatedAt = $null }
    }
    try {
        $raw = Get-Content $StateFile -Raw | ConvertFrom-Json
        return [PSCustomObject]@{
            telegramBot = [bool]$raw.telegramBot
            updatedAt   = $raw.updatedAt
        }
    } catch {
        return [PSCustomObject]@{ telegramBot = $false; updatedAt = $null }
    }
}

function Write-State([bool]$Enabled) {
    New-Item -ItemType Directory -Force -Path $ScriptsDir | Out-Null
    $payload = [ordered]@{
        _comment    = "Managed by scripts/autostart-control.ps1. Missing file means OFF."
        telegramBot = $Enabled
        updatedAt   = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssK")
    }
    $json = $payload | ConvertTo-Json
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($StateFile, $json, $utf8NoBom)
}

function Get-BotProcess {
    $pidValue = $null
    if (Test-Path $PidFile) {
        try { $pidValue = [int]((Get-Content $PidFile -Raw).Trim()) } catch { $pidValue = $null }
    }
    $candidates = @()
    if ($pidValue) {
        $p = Get-CimInstance Win32_Process -Filter "ProcessId=$pidValue" -ErrorAction SilentlyContinue
        if ($p -and $p.CommandLine -match "telegram-pc-bot\.py") { $candidates += $p }
    }
    if (-not $candidates) {
        $candidates = @(Get-CimInstance Win32_Process -Filter "Name='python.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -match "telegram-pc-bot\.py" })
    }
    return $candidates
}

function Move-Entry([string]$Name, [string]$From, [string]$To) {
    $src = Join-Path $From $Name
    if (-not (Test-Path $src)) { return $false }
    New-Item -ItemType Directory -Force -Path $To | Out-Null
    Move-Item -LiteralPath $src -Destination (Join-Path $To $Name) -Force
    return $true
}

function Show-Status {
    $state = Read-State
    $bot = Get-BotProcess
    $hermesActive = Test-Path (Join-Path $StartupDir "Hermes_Gateway_wagent.vbs")
    $omniActive = Test-Path (Join-Path $StartupDir "OmniRoute.lnk")
    $hermesParked = Test-Path (Join-Path $DisabledDir "Hermes_Gateway_wagent.vbs")
    $omniParked = Test-Path (Join-Path $DisabledDir "OmniRoute.lnk")

    $runKey = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -ErrorAction SilentlyContinue
    $chamber = $runKey.'dev.openchamber.desktop'

    Write-Host ""
    Write-Host "AUTOSTART SWITCH" -ForegroundColor Cyan
    Write-Host ("  state file        : " + $StateFile)
    Write-Host ("  telegramBot flag  : " + $(if ($state.telegramBot) { "ON" } else { "OFF" })) -ForegroundColor $(if ($state.telegramBot) { "Green" } else { "Yellow" })
    Write-Host ("  telegram process  : " + $(if ($bot) { "running (pid " + (($bot | ForEach-Object { $_.ProcessId }) -join ", ") + ")" } else { "not running" }))
    Write-Host ("  Hermes gateway    : " + $(if ($hermesActive) { "starts at login" } elseif ($hermesParked) { "parked (off)" } else { "absent" }))
    Write-Host ("  OmniRoute         : " + $(if ($omniActive) { "starts at login" } elseif ($omniParked) { "parked (off)" } else { "absent" }))
    Write-Host ("  OpenChamber       : " + $(if ($chamber) { "starts at login (kept, phone access)" } else { "NOT in Run key" })) -ForegroundColor $(if ($chamber) { "Green" } else { "Red" })
    Write-Host ""
    Write-Host "  Enable :  .\autostart-control.ps1 -Enable"
    Write-Host "  Disable:  .\autostart-control.ps1 -Disable"
    Write-Host ""
}

function Disable-Autostart {
    Write-State $false
    Write-Host "telegramBot flag -> OFF"

    if (-not $TelegramOnly) {
        foreach ($name in $ManagedEntries) {
            if (Move-Entry $name $StartupDir $DisabledDir) {
                Write-Host ("parked startup entry: " + $name)
            }
        }
    } elseif ($TelegramOnly) {
        Write-Host "Hermes/OmniRoute left untouched (-TelegramOnly)"
    }

    $bot = Get-BotProcess
    foreach ($p in $bot) {
        try {
            Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop
            Write-Host ("stopped telegram bot pid " + $p.ProcessId)
        } catch {
            Write-Host ("could not stop pid " + $p.ProcessId + ": " + $_.Exception.Message) -ForegroundColor Yellow
        }
    }
    if ($bot -and (Test-Path $PidFile)) { Remove-Item $PidFile -Force -ErrorAction SilentlyContinue }
    if (-not (Get-BotProcess)) { Remove-Item $PidFile -Force -ErrorAction SilentlyContinue }

    Write-Host "OpenChamber untouched." -ForegroundColor Green
}

function Enable-Autostart {
    Write-State $true
    Write-Host "telegramBot flag -> ON"

    if (-not $TelegramOnly) {
        foreach ($name in $ManagedEntries) {
            if (Move-Entry $name $DisabledDir $StartupDir) {
                Write-Host ("restored startup entry: " + $name)
            }
        }
    } else {
        Write-Host "Hermes/OmniRoute left parked (-TelegramOnly)"
    }

    $bot = Get-BotProcess
    if (-not $bot) {
        if ((Test-Path $BotPy) -and (Get-Command python -ErrorAction SilentlyContinue) -and (Get-Command node -ErrorAction SilentlyContinue)) {
            $python = (Get-Command python).Source
            $spawner = Join-Path $ScriptsDir "spawn-detached.js"
            $out = Join-Path $ScriptsDir "telegram-bot.log"
            $newPid = & node $spawner $python $BotPy $out $ScriptsDir
            if ($LASTEXITCODE -eq 0 -and $newPid -match '^\d+$') {
                Set-Content -Path $PidFile -Value $newPid.Trim() -Encoding ASCII
                Write-Host ("started telegram bot pid " + $newPid.Trim())
            } else {
                Write-Host "spawn failed; bot will start on next opencode launch" -ForegroundColor Yellow
            }
        } else {
            Write-Host "bot script, python or node missing; will start on next opencode launch" -ForegroundColor Yellow
        }
    } else {
        Write-Host ("telegram bot already running (pid " + (($bot | ForEach-Object { $_.ProcessId }) -join ", ") + ")")
    }
    Write-Host "OpenChamber untouched." -ForegroundColor Green
}

function Initialize-Parked {
    if (-not (Test-Path $LegacyDisabledDir)) { return }
    New-Item -ItemType Directory -Force -Path $DisabledDir | Out-Null
    Get-ChildItem $LegacyDisabledDir -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
        Move-Item -LiteralPath $_.FullName -Destination (Join-Path $DisabledDir $_.Name) -Force
    }
    Remove-Item $LegacyDisabledDir -Force -Recurse -ErrorAction SilentlyContinue
}

if ($Enable -and $Disable) { throw "Use either -Enable or -Disable, not both." }

Initialize-Parked

if ($Enable) {
    Enable-Autostart
} elseif ($Disable) {
    Disable-Autostart
} else {
    Show-Status
}
