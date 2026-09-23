# check-jupyter.ps1 - poll JupyterHub server/kernels, report DOWN/IDLE/ERROR signs.
# Reads credentials from scripts/.jupyter.env (never pass tokens on command line).
# SSO-aware: the faculty Hub only answers while the user's SSO session is warm.
# Unreachable API and no-servers both normalize to quiet IDLE-NO-SESSION (never
# alerts). Alerts fire only on state changes while a server is reachable, i.e.
# real mid-training deaths, never on logout/session expiry.
param([string]$SchedulesRoot = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".." | Join-Path -ChildPath "schedules/jupyter_crash"))
$envFile = Join-Path (Split-Path (Split-Path $PSScriptRoot)) "scripts\.jupyter.env"
$pairs = @{}
Get-Content $envFile | Where-Object { $_ -match "=" } | ForEach-Object { $kv = $_ -split "=", 2; $pairs[$kv[0].Trim()] = $kv[1].Trim() }
$base = $pairs["JUPYTERHUB_URL"]; $tok = $pairs["JUPYTERHUB_TOKEN"]; $user = $pairs["JUPYTERHUB_USER"]
$H = @{ Authorization = "token $tok" }
$CheckDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$StateFile = Join-Path $CheckDir "last-state.txt"
$InboxDir = Join-Path (Split-Path -Parent $CheckDir) "inbox"
$lines = @()
try {
  $u = Invoke-RestMethod "$base/hub/api/users/$user" -Headers $H -TimeoutSec 20
} catch { $lines += "HUB-UNREACHABLE $($_.Exception.Message)" }
if ($lines.Count -eq 0) {
  $names = @()
  if ($u.servers) { $names = @($u.servers.PSObject.Properties | ForEach-Object { $_.Name }) }
  if ($names.Count -eq 0) { $lines += "NO-SERVER-RUNNING" }
  else {
    foreach ($n in $names) {
      $s = $u.servers.$n
      if (-not $s.ready) { $lines += "SERVER-NOT-READY:$n"; continue }
      $surl = $s.url
      if ($surl -notmatch "^https?://") { $surl = "$base$surl" }
      try {
        $kernels = Invoke-RestMethod "$surl/api/kernels" -Headers $H -TimeoutSec 20
        if (-not $kernels -or $kernels.Count -eq 0) { $lines += "SERVER-UP-NO-KERNELS:$n" }
        foreach ($k in $kernels) {
          $idle = "unknown"
          try {
            $sess = Invoke-RestMethod "$surl/api/sessions" -Headers $H -TimeoutSec 20
            $match = @($sess | Where-Object { $_.kernel.id -eq $k.id })
            if ($match.Count -gt 0) { $idle = "session:" + $match[0].name }
          } catch { }
          $lines += ("KERNEL name=" + $k.name + " state=" + $k.execution_state + " last=" + $k.last_activity + " " + $idle)
        }
      } catch { $lines += ("KERNEL-API-ERROR:$n " + $_.Exception.Message) }
    }
  }
}
foreach ($l in $lines) { Write-Host $l }
$state = ($lines -join "`n")
if ($state -like "HUB-UNREACHABLE*" -or $state -eq "NO-SERVER-RUNNING") {
  $state = "IDLE-NO-SESSION"
  Write-Host $state
}
$prev = ""
if (Test-Path $StateFile) { $prev = Get-Content $StateFile -Raw }
if ($prev -ne $state) {
  Set-Content $StateFile $state -Encoding UTF8 -NoNewline
  if ($prev -ne "" -and $prev -ne "IDLE-NO-SESSION" -and $state -ne "IDLE-NO-SESSION") {
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    $text = ("jupyter state changed:`n--- was ---`n" + $prev + "`n--- now ---`n" + $state)
    if ($text.Length -gt 4000) { $text = $text.Substring(0, 4000) }
    $payload = @{ text = $text } | ConvertTo-Json -Compress
    if (-not (Test-Path $InboxDir)) { New-Item -ItemType Directory $InboxDir | Out-Null }
    $outFile = Join-Path $InboxDir ("jupyter-" + $ts + ".json")
    [System.IO.File]::WriteAllText($outFile, $payload, [System.Text.UTF8Encoding]::new($false))
    Write-Host ("INBOX-QUEUED " + (Split-Path -Leaf $outFile))
  }
}
