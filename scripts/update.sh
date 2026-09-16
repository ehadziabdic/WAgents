#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "[wagents] update: checking pinned refs (no auto-upgrade)..."
echo "  skills: $(cat "$ROOT/config/skills.json" | python3 -c "import json,sys; print(len(json.load(open(sys.argv[1]))['skills']))" "$ROOT/config/skills.json") entries"
echo "  plugins: see config/plugins.json for pinned refs"
echo "  To update claude-red: set CLAUDE_RED_REF=<sha> and run scripts/install-skills.sh --include-hacker"
bash "$ROOT/scripts/verify-install.sh"
echo "[wagents] update: OK (manual pinned updates only)"
