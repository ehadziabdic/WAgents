#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "[wagents] mcp-skills: verifying MCP integration skills..."

for s in mcp-codebase-memory mcp-second-brain mcp-shared-codebase-memory; do
  test -f "$ROOT/skills/$s/SKILL.md" || { echo "[wagents][fail] mcp skill missing: $s" >&2; exit 1; }
done

echo "[wagents] mcp-skills: OK — 3 MCP skills verified"