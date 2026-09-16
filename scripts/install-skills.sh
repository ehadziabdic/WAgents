#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load group-specific installers if they exist
load_group_installer() {
  local group="$1"
  local script="$ROOT/scripts/install-${group}-skills.sh"
  if [ -f "$script" ]; then
    echo "[wagents] skills: running group $group ..."
    bash "$script" "$@"
  else
    echo "[wagents][warn] group installer $script not found — skipping"
  fi
}

# Run group-specific skill installers
load_group_installer "base"
load_group_installer "mcp"
load_group_installer "awesome"
load_group_installer "obsidian"
load_group_installer "super"
load_group_installer "taste"
load_group_installer "ui-ux"
load_group_installer "anthropic"
load_group_installer "devops"
load_group_installer "ml"

echo "[wagents] skills: checking core skills..."
for s in base-architecture-blueprint base-webapp-testing-basics awesome-security-review super-systematic-debugging super-subagent-driven-development super-requesting-code-review; do
  test -f "$ROOT/skills/$s/SKILL.md" || { echo "[wagents][fail] missing skill $s" >&2; exit 1; }
done

echo "[wagents] skills: OK"
