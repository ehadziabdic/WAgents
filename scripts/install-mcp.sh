#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "[wagents] mcp: validating servers.json..."
python3 -c "import json,sys; json.load(open('$ROOT/mcp/servers.json')); print('[wagents] mcp: servers.json valid')"
echo "[wagents] mcp: required env (set locally, never in git):"
echo "  - GITHUB_TOKEN (github)"
echo "  - TAVILY_API_KEY (tavily, researcher only)"
echo "  - SENTRY_AUTH_TOKEN (sentry, read-only)"
echo "  - SONAR_TOKEN, SONAR_HOST_URL (sonarqube, reviewer)"
echo "  - SEMGREP_APP_TOKEN (semgrep, optional for local rules)"
echo "[wagents] mcp: OK (configure per-client VS Code MCP settings from mcp/servers.json, see docs/mcp.md)"
