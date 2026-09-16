#Requires -Version 5.1
param(
  [ValidateSet("claude-code", "codex", "copilot", "antigravity", "cline", "hermes")]
  [string]$Provider = "copilot",
  [switch]$DryRun,
  [switch]$SkipMcps
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$arguments = @("$Root/bin/wagents.mjs", "install", "--provider", $Provider)
if ($DryRun) { $arguments += "--dry-run" }
if ($SkipMcps) { $arguments += "--skip-mcps" }
& node @arguments
exit $LASTEXITCODE

