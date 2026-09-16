#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$cmd = if ($args.Count -gt 0) { $args[0] } else { "help" }
switch ($cmd) {
  "init" {
    throw "[wagents] init is not implemented; no project files were created. See $Root/docs/architecture.md for project configuration guidance."
  }
  "install" { & "$Root/install.ps1" }
  "update" { & "$Root/scripts/update.ps1" }
  "doctor" { & "$Root/scripts/doctor.ps1" }
  "list" {
    Write-Host "[wagents] agents:"
    (Get-Content "$Root/config/agents.json" | ConvertFrom-Json).agents | ForEach-Object { Write-Host (" - " + $_.id) }
    Write-Host "[wagents] skills:"
    (Get-Content "$Root/config/skills.json" | ConvertFrom-Json).skills | ForEach-Object { Write-Host (" - " + $_.name + " (" + $_.status + ")") }
  }
  default { Write-Host "Usage: wagents.ps1 <init|install|update|doctor|list>" }
}
