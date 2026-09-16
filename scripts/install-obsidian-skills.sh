#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "[wagents] obsidian-skills: verifying obsidian integration skills..."

for s in obsidian-bases obsidian-cli obsidian-defuddle obsidian-json-canvas obsidian-knap obsidian-markdown; do
  test -f "$ROOT/skills/$s/SKILL.md" || { echo "[wagents][fail] obsidian skill missing: $s" >&2; exit 1; }
done

echo "[wagents] obsidian-skills: OK — 6 skills verified"