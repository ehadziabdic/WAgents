#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "[wagents] base-skills: verifying core engineering skills..."

INCLUDE_HACKER=0
for arg in "$@"; do
  case "$arg" in
    --include-hacker) INCLUDE_HACKER=1 ;;
  esac
done

for s in base-architecture-blueprint base-design-references base-webapp-testing-basics; do
  test -f "$ROOT/.github/skills/$s/SKILL.md" || { echo "[wagents][fail] base skill missing: $s" >&2; exit 1; }
done

if [ "$INCLUDE_HACKER" = "1" ]; then
  echo "[wagents] base-skills: vendoring claude-red (SnailSploit/Claude-Red, full copy, pinned)..."
  PINNED_REF="${CLAUDE_RED_REF:-24d7968bab4b883e7f13477afe0fd91f2df3b722}"
  VENDOR_DIR="$ROOT/.github/skills/base-hacker-claude-red/vendor"
  DEST="$VENDOR_DIR/Claude-Red"
  if [ -d "$DEST/Skills" ]; then
    echo "[wagents] base-skills: existing claude-red copy found at vendor/Claude-Red — using it (manual placement respected)."
  else
    rm -rf "$DEST"
    mkdir -p "$VENDOR_DIR"
    git clone --depth 1 https://github.com/SnailSploit/Claude-Red.git "$DEST" || {
      echo "[wagents][fail] could not clone SnailSploit/Claude-Red" >&2
      exit 1
    }
    if [ "$(cd "$DEST" && git rev-parse HEAD)" != "$PINNED_REF" ]; then
      (cd "$DEST" && git fetch --depth 1 origin "$PINNED_REF" && git checkout --detach "$PINNED_REF") \
        || echo "[wagents][warn] could not pin $PINNED_REF — using upstream main HEAD"
    fi
    printf '# Provenance\n- source: https://github.com/SnailSploit/Claude-Red\n- pinned_ref: %s\n- vendored_at: %s\n- exclusive_to: wagent-hacker\n- upstream_license: MIT (see vendor/Claude-Red/LICENSE)\n' "$PINNED_REF" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$VENDOR_DIR/PROVENANCE.md"
    echo "[wagents] base-skills: claude-red vendored (full copy) at $PINNED_REF"
  fi
else
  echo "[wagents] base-skills: claude-red vendoring skipped (use --include-hacker)"
fi
test -f "$ROOT/.github/skills/base-hacker-claude-red/SKILL.md" || { echo "[wagents][fail] base skill missing: base-hacker-claude-red" >&2; exit 1; }

echo "[wagents] base-skills: OK — 4 skills verified"