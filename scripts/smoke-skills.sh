#!/usr/bin/env bash
# smoke-skills.sh — smoke test every registered skill.
# Adapted from the third-party ui-ux smoke-domains.sh / smoke-stacks.sh pattern:
# iterate the registry (skill directories), assert each entry is loadable.
# Catches regressions early (e.g. a skill directory without SKILL.md, or a
# SKILL.md missing its frontmatter name/description).
#
# Exit codes:
#   0 — all skills pass
#   1 — at least one skill failed
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT/skills"

EXPECTED_COUNT="${EXPECTED_SKILL_COUNT:-98}"

if [ ! -d "$SKILLS_DIR" ]; then
  echo "FAIL: skills directory not found at $SKILLS_DIR" >&2
  exit 2
fi

# Single source of truth: enumerate skill directories.
SKILLS=()
while IFS= read -r line; do
  line="${line%$'\r'}"
  [ -n "$line" ] && SKILLS+=("$line")
done < <(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d ! -name '_*' -exec basename {} \; | LC_ALL=C sort)

if [ "${#SKILLS[@]}" -ne "$EXPECTED_COUNT" ]; then
  echo "FAIL: found ${#SKILLS[@]} skills, expected $EXPECTED_COUNT" >&2
  echo "      Set EXPECTED_SKILL_COUNT to override after an intentional change." >&2
  exit 2
fi

echo "Smoke-testing ${#SKILLS[@]} skills:"
fail=0
for s in "${SKILLS[@]}"; do
  ok=1
  [ -f "$SKILLS_DIR/$s/SKILL.md" ] || { ok=0; reason="missing SKILL.md"; }
  if [ "$ok" -eq 1 ]; then
    grep -q '^name:' "$SKILLS_DIR/$s/SKILL.md" || { ok=0; reason="missing name in frontmatter"; }
    grep -q '^description:' "$SKILLS_DIR/$s/SKILL.md" || { ok=0; reason="missing description in frontmatter"; }
  fi
  if [ "$ok" -eq 1 ]; then
    printf '  PASS  %s\n' "$s"
  else
    printf '  FAIL  %-45s %s\n' "$s" "${reason:-unknown}"
    fail=$((fail + 1))
  fi
done

total=${#SKILLS[@]}
echo
if [ "$fail" -gt 0 ]; then
  echo "FAIL: $fail/$total skills failed smoke checks" >&2
  exit 1
fi
echo "OK: $total/$total skills passed"
