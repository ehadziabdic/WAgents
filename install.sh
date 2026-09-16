#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Auto-install MCPs that need npm/global installation
install_mcps() {
  echo "[wagents] Installing MCPs..."

  # codebase-memory-mcp is the only npm-based MCP that should be installed globally
  # It's a persistent local structural index used by orchestrator and specialists
  if command -v npm >/dev/null 2>&1; then
    echo "[wagents] Installing codebase-memory-mcp (npm global)..."
    if npm list -g codebase-memory-mcp >/dev/null 2>&1; then
      echo "[wagents] codebase-memory-mcp already installed globally"
    else
      npm install -g codebase-memory-mcp@0.10.0
      echo "[wagents] codebase-memory-mcp installed"
    fi
  else
    echo "[wagents][warn] npm not found — skipping MCP installation"
    echo "[wagents][info] Other MCPs (context7, playwright, tavily, sentry, etc.)"
    echo "[wagents][info]  are configured via mcp/servers.json and should be installed"
    echo "[wagents][info]  by your MCP client (Copilot, Claude Code, etc.) at runtime."
  fi

  echo "[wagents] MCP installation complete."
}

# Run MCP installation before delegating to wagents.mjs
install_mcps

# Delegate to wagents.mjs for provider plugin installation
exec node "$ROOT/bin/wagents.mjs" install "$@"
