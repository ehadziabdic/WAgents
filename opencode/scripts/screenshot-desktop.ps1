param([string]$OutDir = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".out"), [string]$WindowTitle = "")
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$path = Join-Path $OutDir "shot-$ts.png"
$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
$bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Output $path
