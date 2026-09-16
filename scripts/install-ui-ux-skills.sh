#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "[wagents] ui-ux-skills: verifying ui-ux skills..."

for s in ui-ux-banner-design ui-ux-brand ui-ux-design ui-ux-design-system ui-ux-pro-max ui-ux-slides ui-ux-ui-styling; do
  test -f "$ROOT/skills/$s/SKILL.md" || { echo "[wagents][fail] ui-ux skill missing: $s" >&2; exit 1; }
done

echo "[wagents] ui-ux-skills: OK — 7 skills verified"