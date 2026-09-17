#!/usr/bin/env bash
# bump-version.sh — bump the wagents release version across EVERY version-bearing file.
# Thin cross-platform wrapper: all logic lives in scripts/sync-release-version.mjs
# (node-only, works on Linux / macOS / Windows).
#
# Usage: scripts/bump-version.sh <version>   e.g. 0.4.0
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec node "$ROOT/scripts/sync-release-version.mjs" "$@"
