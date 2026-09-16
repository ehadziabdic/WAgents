#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "[wagents] taste-skills: verifying taste skills..."

for s in taste-brandkit taste-brutalist-skill taste-gpt-tasteskill taste-image-to-code-skill taste-imagegen-frontend-mobile taste-imagegen-frontend-web taste-minimalist-skill taste-output-skill taste-redesign-skill taste-skill taste-soft-skill taste-stitch-skill; do
  test -f "$ROOT/.github/skills/$s/SKILL.md" || { echo "[wagents][fail] taste skill missing: $s" >&2; exit 1; }
done

echo "[wagents] taste-skills: OK — 12 skills verified"