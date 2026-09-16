#!/usr/bin/env bash
# SessionStart hook for wagents — cross-platform JSON context injection.
# Integrated from third-party hooks/super/session-start, adapted to wagents:
# emits platform-appropriate JSON so the orchestrator context is actually
# injected by Claude Code / Cursor / Copilot, and plain text otherwise.
set -euo pipefail

WAGENTS_CONTEXT="[wagents] Session initialized.
- Main agents: wagent (default; orchestrator+architect merged) and wagent-hacker (authorized offensive security mode). Mains never call each other; only mains delegate.
- Specialists: frontend-designer, backend-engineer, security-engineer, code-reviewer, debugger, qa-engineer, research-specialist, documentation-specialist, ml-engineer, devops-engineer.
- Available slash commands: /wagents:brainstorm, /wagents:plan, /wagents:execute, /wagents:verify, /wagents:review, /wagents:debug, /wagents:taste.
- Engineering principles: Red-Green TDD, verification before completion, least privilege, zero secrets in source.
- Skills: 98 across anth/awesome/base/devops/mcp/ml/obsidian/super/taste/ui-ux groups. Use the Skill tool; see .github/skills/<name>/SKILL.md.
- All agents may use mcp-codebase-memory (query-first before scanning)."

# Escape string for JSON embedding using bash parameter substitution.
escape_for_json() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

escaped=$(escape_for_json "$WAGENTS_CONTEXT")

# Cursor hooks expect additional_context (snake_case).
# Claude Code hooks expect hookSpecificOutput.additionalContext (nested).
# Copilot CLI (v1.0.11+) and others expect additionalContext (top-level, SDK standard).
# Claude Code reads BOTH additional_context and hookSpecificOutput without
# deduplication, so we must emit only the field the current platform consumes.
if [ -n "${CURSOR_PLUGIN_ROOT:-}" ]; then
  printf '{\n  "additional_context": "%s"\n}\n' "$escaped" | cat
elif [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -z "${COPILOT_CLI:-}" ]; then
  printf '{\n  "hookSpecificOutput": {\n    "hookEventName": "SessionStart",\n    "additionalContext": "%s"\n  }\n}\n' "$escaped" | cat
elif [ -n "${COPILOT_CLI:-}" ]; then
  printf '{\n  "additionalContext": "%s"\n}\n' "$escaped" | cat
else
  # No plugin runtime detected — plain text keeps the human-readable banner.
  printf '%s\n' "$WAGENTS_CONTEXT"
fi

exit 0

