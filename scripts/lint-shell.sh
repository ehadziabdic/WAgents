#!/usr/bin/env bash
# lint-shell.sh — run shellcheck over every bash script in the repo.
# Integrated from third-party super/lint-shell.sh, adapted to the wagents layout.
#
# Usage: scripts/lint-shell.sh            # lint all tracked scripts
#        scripts/lint-shell.sh FILE...    # lint specific files
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "[wagents][warn] shellcheck not found — install it to lint (https://shellcheck.net)" >&2
  exit 0
fi

if [ "$#" -gt 0 ]; then
  FILES=("$@")
else
  mapfile -t FILES < <(
    {
      find "$ROOT/scripts" "$ROOT/hooks" -type f -name '*.sh' 2>/dev/null
      [ -f "$ROOT/install.sh" ] && echo "$ROOT/install.sh"
    } | sort -u
  )
fi

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "[wagents] lint-shell: no scripts found"
  exit 0
fi

fail=0
for f in "${FILES[@]}"; do
  if shellcheck -x "$f"; then
    echo "[wagents] lint-shell: [ok] ${f#"$ROOT"/}"
  else
    echo "[wagents] lint-shell: [fail] ${f#"$ROOT"/}" >&2
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  echo "[wagents] lint-shell: FAILED" >&2
  exit 1
fi
echo "[wagents] lint-shell: all ${#FILES[@]} script(s) passed"
