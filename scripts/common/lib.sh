#!/usr/bin/env bash
# wagents common lib - unix
set -euo pipefail

log() { printf '[wagents] %s\n' "$*"; }
warn() { printf '[wagents][warn] %s\n' "$*" >&2; }
fail() { printf '[wagents][fail] %s\n' "$*" >&2; exit 1; }

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

check_prereqs() {
  log "Checking prerequisites..."
  command -v git >/dev/null 2>&1 || fail "git not found"
  command -v python3 >/dev/null 2>&1 || warn "python3 not found (needed for verify)"
  if command -v gh >/dev/null 2>&1; then log "gh: found"; else warn "gh not found (optional)"; fi
  if command -v node >/dev/null 2>&1; then log "node: found"; else warn "node not found (needed for some MCPs)"; fi
  log "Prereqs OK"
}

install_skills() {
  local include_hacker="${1:-0}"
  log "Installing skills (hacker=$include_hacker)..."
  if [ "$include_hacker" = "1" ]; then
    bash "$ROOT_DIR/scripts/install-skills.sh" --include-hacker
  else
    bash "$ROOT_DIR/scripts/install-skills.sh"
  fi
}

install_mcp() {
  log "Configuring MCP..."
  bash "$ROOT_DIR/scripts/install-mcp.sh"
}

link_configs() {
  log "Linking configs (repo is source of truth, no global overwrite)..."
  test -f "$ROOT_DIR/.github/copilot-instructions.md" || fail "missing copilot-instructions"
  test -f "$ROOT_DIR/mcp/servers.json" || fail "missing mcp/servers.json"
  log "Configs OK"
}

verify_install() {
  bash "$ROOT_DIR/scripts/verify-install.sh"
}
