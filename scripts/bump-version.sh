#!/usr/bin/env bash
# bump-version.sh — bump the wagents release version across manifests.
# Integrated from third-party super/bump-version.sh, adapted to the wagents layout.
#
# Usage: scripts/bump-version.sh <version>   e.g. 1.4.2
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "usage: $0 <version>  (e.g. $0 1.4.2)" >&2
  exit 1
fi
if ! printf '%s' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.-]+)?$'; then
  echo "error: '$VERSION' is not a semver string" >&2
  exit 1
fi

bump_json() {
  local file="$1" key="$2"
  [ -f "$file" ] || { echo "[wagents] bump: skip (missing) $file"; return 0; }
  python3 - "$file" "$key" "$VERSION" <<'PY'
import json, re, sys
path, key, version = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, encoding="utf-8") as fh:
    text = fh.read()
data = json.loads(text)
data[key] = version
# Re-serialize preserving key order (dicts keep insertion order) and trailing newline.
out = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
with open(path, "w", encoding="utf-8", newline="\n") as fh:
    fh.write(out)
print(f"[wagents] bump: {path} -> {key}={version}")
PY
}

# 1. VERSION file (single source of truth)
printf '%s\n' "$VERSION" > "$ROOT/VERSION"
echo "[wagents] bump: VERSION -> $VERSION"

# 2. Plugin manifests
bump_json "$ROOT/manifest.json" "version"

# 3. Node manifest (if present)
bump_json "$ROOT/package.json" "version"

echo "[wagents] bump: done. Remember to git commit the version files."
