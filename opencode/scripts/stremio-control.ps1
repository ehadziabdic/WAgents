# stremio-control.ps1 - non-interactive control for the local Stremio server.
#
# Mirrors "C:\Users\eminha\Documents\scripts\Stremio Server Starter.bat":
#   option 1 (Start) = -Action Start, option 2 (Stop) = -Action Stop.
# The bat stays the human menu; this file is what agents and the Telegram
# bot call, because it never prompts and always exits with a status line.
#
#   .\stremio-control.ps1 -Action Status
#   .\stremio-control.ps1 -Action Start [-SkipGist] [-TimeoutSeconds 360]
#   .\stremio-control.ps1 -Action Stop [-KeepEngine]
#
# Exit codes: 0 ok, 1 action failed, 2 prerequisites missing.

param(
    [ValidateSet("Start", "Stop", "Status")]
    [string]$Action = "Status",
    [switch]$SkipGist,
    [switch]$KeepEngine,
    [int]$TimeoutSeconds = 360
)

$ErrorActionPreference = "Continue"

$ComposeDir = "C:\Users\eminha\Documents\Projects\StremioServer\server\docker"
$GistScript = Join-Path $ComposeDir "update-gist.ps1"

function Write-Step([string]$Message) {
    Write-Output ("[stremio] " + $Message)
}

if (-not (Test-Path $ComposeDir)) {
    Write-Output ("[stremio] compose folder missing: " + $ComposeDir)
    exit 2
}

$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
    Write-Output "[stremio] docker CLI not found in PATH"
    exit 2
}

function Test-Engine {
    try {
        docker info --format "{{.ServerVersion}}" 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Wait-Engine([int]$Seconds) {
    $deadline = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-Engine) { return $true }
        Start-Sleep -Seconds 3
    }
    return (Test-Engine)
}

function Get-ComposeState {
    Push-Location $ComposeDir
    try {
        $out = docker compose ps --format "{{.Name}} {{.State}}" 2>&1
    } finally {
        Pop-Location
    }
    return (($out | Out-String).Trim())
}

if ($Action -eq "Status") {
    if (-not (Test-Engine)) {
        Write-Output "[stremio] docker engine: not running"
        exit 1
    }
    Write-Output "[stremio] docker engine: running"
    $state = Get-ComposeState
    if ($state) {
        Write-Output $state
    } else {
        Write-Output "[stremio] no compose containers (server is down)"
    }
    exit 0
}

if ($Action -eq "Start") {
    if (Test-Engine) {
        Write-Step "docker engine already running"
    } else {
        Write-Step "starting Docker Desktop"
        try {
            docker desktop start 2>&1 | Out-Null
        } catch {
            $exe = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
            if (Test-Path $exe) { Start-Process $exe | Out-Null }
        }
        if (-not (Wait-Engine $TimeoutSeconds)) {
            Write-Output ("[stremio] docker engine did not come up within " + $TimeoutSeconds + " s")
            exit 1
        }
        Write-Step "docker engine ready"
    }

    Push-Location $ComposeDir
    try {
        $up = docker compose up -d 2>&1
        $upCode = $LASTEXITCODE
    } finally {
        Pop-Location
    }
    ($up | Out-String).Trim() | Write-Output
    if ($upCode -ne 0) {
        Write-Output "[stremio] docker compose up failed"
        exit 1
    }

    Write-Step "waiting 15 s for the cloudflare tunnel"
    Start-Sleep -Seconds 15

    if ($SkipGist) {
        Write-Step "gist update skipped (-SkipGist)"
    } elseif (Test-Path $GistScript) {
        Write-Step "updating gist"
        $gist = & powershell -NoProfile -ExecutionPolicy Bypass -File $GistScript 2>&1
        ($gist | Out-String).Trim() | Write-Output
    } else {
        Write-Step "update-gist.ps1 missing, skipped"
    }

    Write-Step "server is live"
    Get-ComposeState | Write-Output
    exit 0
}

if ($Action -eq "Stop") {
    if (-not (Test-Engine)) {
        Write-Step "docker engine already stopped"
        exit 0
    }
    Push-Location $ComposeDir
    try {
        $down = docker compose down 2>&1
        $downCode = $LASTEXITCODE
    } finally {
        Pop-Location
    }
    ($down | Out-String).Trim() | Write-Output
    if ($downCode -ne 0) {
        Write-Output "[stremio] docker compose down failed"
        exit 1
    }
    if ($KeepEngine) {
        Write-Step "containers stopped, docker engine kept running (-KeepEngine)"
    } else {
        try {
            docker desktop stop 2>&1 | Out-Null
            Write-Step "docker desktop stopped"
        } catch {
            Write-Step ("could not stop docker desktop: " + $_.Exception.Message)
        }
    }
    Write-Step "server is down"
    exit 0
}
