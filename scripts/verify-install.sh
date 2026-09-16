#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0
check() { if eval "$2"; then echo "[ok] $1"; else echo "[missing] $1"; fail=1; fi; }
check "wagent" "test -f $ROOT/agents/wagent.agent.md"
for a in frontend-designer backend-engineer security-engineer wagent-hacker code-reviewer debugger qa-engineer research-specialist documentation-specialist ml-engineer devops-engineer; do
  check "agent:$a" "test -f $ROOT/agents/$a.agent.md"
done
for s in base-architecture-blueprint base-design-references base-webapp-testing-basics base-hacker-claude-red awesome-security-review mcp-codebase-memory mcp-second-brain mcp-shared-codebase-memory super-systematic-debugging super-subagent-driven-development super-requesting-code-review anth-docx anth-pdf anth-pptx anth-xlsx anth-claude-api anth-webapp-testing anth-doc-coauthoring anth-mcp-builder devops-audit devops-runbook devops-terraform-review ml-solution-design model-serving llm-rag llm-guardrails; do
  check "skill:$s" "test -f $ROOT/skills/$s/SKILL.md"
done
for f in typescript.instructions.md python.instructions.md react.instructions.md security.instructions.md testing.instructions.md documentation.instructions.md; do
  check "instruction:$f" "test -f $ROOT/instructions/$f"
done
check "mcp/servers.json" "test -f $ROOT/mcp/servers.json"
check "mcp/README" "test -f $ROOT/mcp/README.md"
check "config/skills.json" "test -f $ROOT/config/skills.json"
check "config/plugins.json" "test -f $ROOT/config/plugins.json"
check "config/agents.json" "test -f $ROOT/config/agents.json"
check "config/permissions.json" "test -f $ROOT/config/permissions.json"
check "manifest.json" "test -f $ROOT/manifest.json"
check "install.sh" "test -f $ROOT/install.sh"
check "install.ps1" "test -f $ROOT/install.ps1"
check "scripts/doctor.sh" "test -f $ROOT/scripts/doctor.sh"
check "scripts/update.sh" "test -f $ROOT/scripts/update.sh"
check "scripts/install-skills.sh" "test -f $ROOT/scripts/install-skills.sh"
check "scripts/install-mcp.sh" "test -f $ROOT/scripts/install-mcp.sh"
check "scripts/install-group.sh" "test -f $ROOT/scripts/install-group.sh"
check "scripts/install-base-skills.sh" "test -f $ROOT/scripts/install-base-skills.sh"
check "scripts/install-mcp-skills.sh" "test -f $ROOT/scripts/install-mcp-skills.sh"
check "scripts/install-awesome-skills.sh" "test -f $ROOT/scripts/install-awesome-skills.sh"
check "scripts/install-obsidian-skills.sh" "test -f $ROOT/scripts/install-obsidian-skills.sh"
check "scripts/install-super-skills.sh" "test -f $ROOT/scripts/install-super-skills.sh"
check "scripts/install-taste-skills.sh" "test -f $ROOT/scripts/install-taste-skills.sh"
check "scripts/install-ui-ux-skills.sh" "test -f $ROOT/scripts/install-ui-ux-skills.sh"
check "scripts/install-anthropic-skills.sh" "test -f $ROOT/scripts/install-anthropic-skills.sh"
check "scripts/install-devops-skills.sh" "test -f $ROOT/scripts/install-devops-skills.sh"
check "scripts/install-ml-skills.sh" "test -f $ROOT/scripts/install-ml-skills.sh"
check "scripts/bump-version.sh" "test -f $ROOT/scripts/bump-version.sh"
check "scripts/lint-shell.sh" "test -f $ROOT/scripts/lint-shell.sh"
check "scripts/validate-csv.py" "test -f $ROOT/scripts/validate-csv.py"
check "scripts/sync-release-version.mjs" "test -f $ROOT/scripts/sync-release-version.mjs"
check "scripts/validate-agent-guide.py" "test -f $ROOT/scripts/validate-agent-guide.py"
check "scripts/smoke-skills.sh" "test -f $ROOT/scripts/smoke-skills.sh"
check "hooks/run-hook.cmd" "test -f $ROOT/hooks/run-hook.cmd"
check "bin/wagents" "test -f $ROOT/bin/wagents"
check "bin/wagents.ps1" "test -f $ROOT/bin/wagents.ps1"
check "scripts/common/lib" "test -f $ROOT/scripts/common/lib.sh"
check "scripts/doctor.ps1" "test -f $ROOT/scripts/doctor.ps1"
check "scripts/update.ps1" "test -f $ROOT/scripts/update.ps1"
check ".env.example" "test -f $ROOT/.env.example"
check "hooks/README" "test -f $ROOT/hooks/hooks.json"
check "hooks/session-start.sh" "test -f $ROOT/hooks/session-start.sh"
check "copilot-instructions" "test -f $ROOT/.github/copilot-instructions.md"
check "README" "test -f $ROOT/README.md"
check "LICENSE" "test -f $ROOT/LICENSE"
check ".gitignore" "test -f $ROOT/.gitignore"
for d in architecture.md skills.md mcp.md security.md troubleshooting.md ui-references.md; do
  check "docs:$d" "test -f $ROOT/docs/$d"
done
python3 -c "import json; [json.load(open(f)) for f in ['$ROOT/manifest.json','$ROOT/mcp/servers.json','$ROOT/config/skills.json','$ROOT/config/plugins.json','$ROOT/config/agents.json','$ROOT/config/permissions.json']]" && echo "[ok] json-valid" || { echo "[missing] json-valid"; fail=1; }
# Secret scan over wagents-owned surfaces only (config, mcp, scripts, agents,
# instructions). Vendored third-party skill bodies are reviewed at vendor time and
# deliberately document credential formats (e.g. `ghp_your_github_token`, `sk-ant-...`),
# so scanning them produces false positives.
if grep -RIn --exclude=verify-install.sh "sk-ant-\|ghp_\|github_pat_\|AKIA" \
    "$ROOT/config" "$ROOT/mcp" "$ROOT/scripts" "$ROOT/agents" \
    "$ROOT/instructions" "$ROOT/.github/copilot-instructions.md" 2>/dev/null; then
  echo "[missing] secret-scan"; fail=1
else echo "[ok] secret-scan"; fi
exit $fail

