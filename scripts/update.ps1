#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Write-Host "[wagents] update (windows): checking pinned refs (no auto-upgrade)..."
$skills = (Get-Content "$Root/config/skills.json" | ConvertFrom-Json).skills.Count
Write-Host "  skills: $skills entries"
Write-Host "  plugins: see config/plugins.json for pinned refs"
Write-Host "  To update claude-red: set `$env:CLAUDE_RED_REF=<sha> and re-run install.ps1 -IncludeHacker"
& "$Root/scripts/doctor.ps1"
Write-Host "[wagents] update: OK (manual pinned updates only)"
