#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Resolve group installer path relative to scripts/
GROUP_INSTALLER="./install-${1:-}.sh"
if [ ! -f "$ROOT/scripts/$GROUP_INSTALLER" ]; then
  echo "[wagents][error] No installer for group '$1'. Available: base, mcp, awesome, obsidian, super, taste, ui-ux, ui-skills" >&2
  exit 1
fi

echo "[wagents] skills[$1]: running group installer..."
bash "$ROOT/scripts/$GROUP_INSTALLER"