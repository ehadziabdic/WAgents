#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "[wagents] doctor..."
bash "$ROOT/scripts/verify-install.sh" || exit 1
command -v git >/dev/null && echo "[ok] git" || echo "[missing] git"
command -v gh >/dev/null && echo "[ok] gh" || echo "[warn] gh missing (optional)"
command -v node >/dev/null && echo "[ok] node" || echo "[warn] node missing (needed for some MCPs)"
command -v python3 >/dev/null && echo "[ok] python3" || echo "[warn] python3 missing"
test -d "$ROOT/skills/base-hacker-claude-red/vendor/Claude-Red/Skills" && echo "[ok] hacker vendor" || echo "[info] hacker vendor not installed (use --include-hacker)"
echo "[wagents] doctor complete."
