<#
.SYNOPSIS
    Turns the two noisy logon tasks off (or back on) with a single UAC click.

.DESCRIPTION
    Both tasks are ACL-protected, so changing them needs elevation. State is read
    without elevation; only the change elevates.

      cua-driver-serve   logs on with RunLevel Highest and flashes an elevated
                         PowerShell window at every boot. Disabling the task stops
                         the flash; the driver itself stays installed and can be
                         started on demand.
      OpenClaw Gateway   points at C:\Users\eminha\.openclaw\gateway.cmd, which does
                         not exist, so it flashes a console and exits 1.

    Nothing is deleted. Both tasks keep their definitions.

.PARAMETER Only
    Restrict the action to one task. Accepts either task name, e.g.
    -Only 'OpenClaw Gateway' or -Only 'cua-driver-serve'. Default: both.

.PARAMETER Enable
    Turn the selected tasks back on.

.PARAMETER Status
    Print the current state only. Never elevates.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File disable-login-popups.ps1 -Status
.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File disable-login-popups.ps1 -Only 'OpenClaw Gateway'
.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File disable-login-popups.ps1 -Enable
#>
param(
    [switch]$Enable,
    [switch]$Status,
    [string]$Only
)

$ErrorActionPreference = 'Stop'
$AllTaskNames = @('cua-driver-serve', 'OpenClaw Gateway')
if ($Only) {
    $match = $AllTaskNames | Where-Object { $_ -ieq $Only }
    if (-not $match) { throw "Unknown -Only value '$Only'. Valid: $($AllTaskNames -join ', ')" }
    $TaskNames = @($match)
}
else {
    $TaskNames = $AllTaskNames
}
$LogPath = Join-Path $env:TEMP 'wagents-login-popups.log'
$WorkerPath = Join-Path $env:TEMP 'wagents-login-popups-worker.ps1'

function Show-State {
    Write-Host "LOGIN TASK STATE"
    foreach ($name in $TaskNames) {
        $task = Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
        if ($task) {
            Write-Host ("  {0,-18} : {1}" -f $name, $task.State)
        }
        else {
            Write-Host ("  {0,-18} : not installed" -f $name)
        }
    }
}

if ($Status) {
    Show-State
    return
}

$verb = if ($Enable) { 'Enable' } else { 'Disable' }
Show-State
Write-Host ""

$map = ($TaskNames | ForEach-Object { "'$_'" }) -join ', '
$workerBody = @'
$ErrorActionPreference = 'Continue'
$log = 'LOGPATH'
"start $(Get-Date -Format o)" | Set-Content -Path $log -Encoding UTF8
foreach ($n in @(NAMES)) {
    try {
        VERB-ScheduledTask -TaskName $n -ErrorAction Stop | Out-Null
        "$n VERB ok" | Add-Content -Path $log -Encoding UTF8
    } catch {
        "$n VERB failed: $($_.Exception.Message)" | Add-Content -Path $log -Encoding UTF8
    }
}
"done $(Get-Date -Format o)" | Add-Content -Path $log -Encoding UTF8
'@
$workerBody = $workerBody.Replace('LOGPATH', $LogPath).Replace('NAMES', $map).Replace('VERB', $verb)
Set-Content -Path $WorkerPath -Value $workerBody -Encoding UTF8

Remove-Item $LogPath -Force -ErrorAction SilentlyContinue
Write-Host "Requesting elevation: one UAC prompt, click Yes."
try {
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -WindowStyle Hidden `
        -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$WorkerPath`"" -ErrorAction Stop
}
catch {
    Write-Host "Elevation not granted: $($_.Exception.Message)"
    exit 1
}

$deadline = (Get-Date).AddSeconds(120)
$finished = $false
while ((Get-Date) -lt $deadline) {
    if (Test-Path $LogPath) {
        $content = Get-Content $LogPath -Raw -ErrorAction SilentlyContinue
        if ($content -match 'done ') { $finished = $true; break }
    }
    Start-Sleep -Milliseconds 500
}

if (-not $finished) {
    Write-Host "No result yet. The UAC prompt may still be waiting on screen."
    exit 1
}

Write-Host ""
Get-Content $LogPath
Write-Host ""
Show-State
