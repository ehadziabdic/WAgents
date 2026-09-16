#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "[wagents] awesome-skills: verifying curated skills..."

for s in awesome-documentation-writer awesome-drawio awesome-microsoft-docs awesome-security-review; do
  test -f "$ROOT/.github/skills/$s/SKILL.md" || { echo "[wagents][fail] awesome skill missing: $s" >&2; exit 1; }
done

echo "[wagents] awesome-skills: OK — 4 skills verified"