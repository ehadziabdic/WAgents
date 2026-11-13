# pc-commands.ps1 - the pinned PC command surface for agents.
#
# One entry point, no prompts, always exits with a short human status line.
# Agents map a natural-language phrase to one of these verbs (see the
# "Pinned PC commands" section in AGENTS.md). The Telegram bot calls the
# same scripts, so behaviour cannot drift between chat and phone.
#
#   .\pc-commands.ps1 stremio-start [-SkipGist]
#   .\pc-commands.ps1 stremio-stop [-KeepEngine]
#   .\pc-commands.ps1 stremio-status
#   .\pc-commands.ps1 telegram-start
#   .\pc-commands.ps1 telegram-stop
#   .\pc-commands.ps1 telegram-status
#   .\pc-commands.ps1 health
#   .\pc-commands.ps1 training-status
#   .\pc-commands.ps1 docker-status
#   .\pc-commands.ps1 autostart-status
#   .\pc-commands.ps1 notify -Text "message"
#
# Exit codes are propagated from the underlying script (0 ok, non-zero failed).

param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet(
        "stremio-start", "stremio-stop", "stremio-status",
        "telegram-start", "telegram-stop", "telegram-status",
        "health", "training-status", "docker-status", "autostart-status",
        "notify"
    )]
    [string]$Command,
    [string]$Text = "",
    [switch]$SkipGist,
    [switch]$KeepEngine
)

$ErrorActionPreference = "Continue"
$Root = $PSScriptRoot
$ConfigRoot = Split-Path -Parent $Root

function Get-TrainingProcesses {
    Get-CimInstance Win32_Process -Filter "Name='python.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match "train\.py" }
}

function Show-TrainingStatus {
    $procs = @(Get-TrainingProcesses)
    if ($procs.Count -eq 0) {
        Write-Output "[training] no train.py process is running"
    } else {
        foreach ($p in $procs) {
            $elapsed = ""
            if ($p.CreationDate) {
                $span = (Get-Date) - $p.CreationDate
                $elapsed = (" up " + [int]$span.TotalHours + "h " + $span.Minutes + "m")
            }
            Write-Output ("[training] running: pid " + $p.ProcessId + $elapsed)
        }
    }

    $alarm = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match "stall_alarm" })
    Write-Output ("[training] stall alarm: " + $(if ($alarm.Count -gt 0) { "armed (pid " + (($alarm | ForEach-Object { $_.ProcessId }) -join ", ") + ")" } else { "not running" }))

    $alive = @(Get-CimInstance Win32_Process -Filter "Name='python.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match "keep_windows_alive" })
    Write-Output ("[training] sleep guard: " + $(if ($alive.Count -gt 0) { "active" } else { "not running" }))

    $watchFile = Join-Path $ConfigRoot "schedules\training_check\watch.json"
    if (Test-Path $watchFile) {
        try {
            $watch = Get-Content $watchFile -Raw | ConvertFrom-Json
            $log = $watch.logPath
            if ($log -and (Test-Path $log)) {
                $info = Get-Item $log
                Write-Output ("[training] watched log: " + $log)
                Write-Output ("[training] last write: " + $info.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"))
                $tail = Get-Content $log -Tail 5 -ErrorAction SilentlyContinue
                foreach ($line in $tail) { Write-Output ("  " + $line) }
            }
        } catch {
            Write-Output ("[training] could not read watch.json: " + $_.Exception.Message)
        }
    }
}

function Get-BotProcesses {
    Get-CimInstance Win32_Process -Filter "Name='python.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match "telegram-pc-bot\.py" }
}

switch ($Command) {
    "stremio-start" {
        $psArgs = @("-Action", "Start")
        if ($SkipGist) { $psArgs += "-SkipGist" }
        & (Join-Path $Root "stremio-control.ps1") @psArgs
        exit $LASTEXITCODE
    }
    "stremio-stop" {
        $psArgs = @("-Action", "Stop")
        if ($KeepEngine) { $psArgs += "-KeepEngine" }
        & (Join-Path $Root "stremio-control.ps1") @psArgs
        exit $LASTEXITCODE
    }
    "stremio-status" {
        & (Join-Path $Root "stremio-control.ps1") -Action Status
        exit $LASTEXITCODE
    }
    "telegram-start" {
        & (Join-Path $Root "autostart-control.ps1") -Enable -TelegramOnly
        $deadline = (Get-Date).AddSeconds(25)
        while ((Get-Date) -lt $deadline -and -not (Get-BotProcesses)) {
            Start-Sleep -Milliseconds 500
        }
        $bot = @(Get-BotProcesses)
        if ($bot.Count -eq 0) {
            Write-Output "[telegram] bot did not start; check scripts/telegram-bot.log"
            exit 1
        }
        $msg = "[pc] Telegram service is active (pid " + (($bot | ForEach-Object { $_.ProcessId }) -join ", ") + ") at " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        & (Join-Path $Root "tg-send.ps1") -Text $msg | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Output "[telegram] bot is running but the confirmation message failed to send"
            exit 1
        }
        Write-Output ("[telegram] bot running (pid " + (($bot | ForEach-Object { $_.ProcessId }) -join ", ") + "), confirmation sent")
        exit 0
    }
    "telegram-stop" {
        & (Join-Path $Root "autostart-control.ps1") -Disable -TelegramOnly
        exit $LASTEXITCODE
    }
    "telegram-status" {
        $bot = @(Get-BotProcesses)
        $state = "OFF"
        $stateFile = Join-Path $Root ".autostart.json"
        if (Test-Path $stateFile) {
            try {
                if ((Get-Content $stateFile -Raw | ConvertFrom-Json).telegramBot -eq $true) { $state = "ON" }
            } catch { }
        }
        Write-Output ("[telegram] autostart flag: " + $state)
        Write-Output ("[telegram] process: " + $(if ($bot.Count -gt 0) { "running (pid " + (($bot | ForEach-Object { $_.ProcessId }) -join ", ") + ")" } else { "not running" }))
        exit $(if ($bot.Count -gt 0) { 0 } else { 1 })
    }
    "health" {
        & (Join-Path $Root "smoke-test.ps1")
        exit $LASTEXITCODE
    }
    "training-status" {
        Show-TrainingStatus
        exit 0
    }
    "docker-status" {
        $out = docker info --format "engine {{.ServerVersion}} | containers {{.Containers}} running {{.ContainersRunning}}" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Output "[docker] engine not reachable"
            exit 1
        }
        Write-Output ("[docker] " + (($out | Out-String).Trim()))
        exit 0
    }
    "autostart-status" {
        & (Join-Path $Root "autostart-control.ps1") -Status
        exit 0
    }
    "notify" {
        if (-not $Text) {
            Write-Output "[notify] -Text is required"
            exit 2
        }
        & (Join-Path $Root "tg-send.ps1") -Text $Text
        exit $LASTEXITCODE
    }
}
