#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Keep installation and dry-run handling in the cross-platform CLI.
exec node "$ROOT/bin/wagents.mjs" install "$@"
