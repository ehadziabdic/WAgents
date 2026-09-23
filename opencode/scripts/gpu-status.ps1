try { nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv 2>&1 } catch { Write-Host "NO-NVIDIA" }
Write-Host "---PROCS---"
Get-Process python*,ollama* -ErrorAction SilentlyContinue | Select-Object ProcessName, Id, CPU | Format-Table | Out-String | Write-Host
