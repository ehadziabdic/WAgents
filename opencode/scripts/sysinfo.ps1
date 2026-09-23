$cpu = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1).CounterSamples.CookedValue
$os = Get-CimInstance Win32_OperatingSystem
$ramUsed = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory)/1MB,1)
$ramTot = [math]::Round($os.TotalVisibleMemorySize/1MB,1)
$disk = Get-PSDrive C | Select-Object Used, Free
$up = (Get-Date) - $os.LastBootUpTime
Write-Host ("CPU:{0}% RAM:{1}/{2}GB DISK-C-free:{3}GB Uptime:{4}d{5}h" -f [math]::Round($cpu), $ramUsed, $ramTot, [math]::Round($disk.Free/1GB,1), $up.Days, $up.Hours)
Write-Host "---TOP-CPU---"
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 ProcessName, Id, @{n="CPUmin";e={[math]::Round($_.CPU/60,1)}} | Format-Table -AutoSize | Out-String | Write-Host
try { nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader 2>$null | ForEach-Object { Write-Host ("GPU:" + $_) } } catch { }
Write-Host "---JUPYTER---"
& (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".." | Join-Path -ChildPath "schedules/jupyter_crash/check-jupyter.ps1")
