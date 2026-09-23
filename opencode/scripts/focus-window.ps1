param([string]$Title = "Brave")
Add-Type @"
using System; using System.Runtime.InteropServices;
public class Win32 { [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h); }
"@
$proc = Get-Process | Where-Object { $_.MainWindowTitle -like "*$Title*" -and $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $proc) { Write-Host "NOT-FOUND:$Title"; exit 1 }
[Win32]::SetForegroundWindow($proc.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 400
Write-Host "FOCUSED:$($proc.MainWindowTitle)"
