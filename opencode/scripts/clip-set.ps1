param([string]$Text = "")
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Clipboard]::SetText($Text)
Write-Host "CLIP-SET"
