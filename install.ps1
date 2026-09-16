param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("claude-code", "codex", "copilot", "antigravity", "cline", "hermes")]
  [string]$Provider,
  [switch]$DryRun
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

# Auto-install MCPs that need npm/global installation
function Install-MCPs {
  Write-Host "[wagents] Installing MCPs..."

  # codebase-memory-mcp is the only npm-based MCP that should be installed globally
  if (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-Host "[wagents] Checking codebase-memory-mcp (npm global)..."
    try {
      npm list -g codebase-memory-mcp 2>$null | Out-Null
      Write-Host "[wagents] codebase-memory-mcp already installed globally"
    } catch {
      Write-Host "[wagents] Installing codebase-memory-mcp@0.10.0 (npm global)..."
      npm install -g codebase-memory-mcp@0.10.0
      Write-Host "[wagents] codebase-memory-mcp installed"
    }
  } else {
    Write-Host "[wagents][warn] npm not found — skipping MCP installation"
    Write-Host "[wagents][info] Other MCPs (context7, playwright, tavily, sentry, etc.)"
    Write-Host "[wagents][info]  are configured via mcp/servers.json and should be installed"
    Write-Host "[wagents][info]  by your MCP client (Copilot, Claude Code, etc.) at runtime."
  }

  Write-Host "[wagents] MCP installation complete."
}

# Run MCP installation before delegating to wagents.mjs
Install-MCPs

# Delegate to wagents.mjs for provider plugin installation
$arguments = @("$Root/bin/wagents.mjs", "install", "--provider", $Provider)
if ($DryRun) { $arguments += "--dry-run" }
& node @arguments
