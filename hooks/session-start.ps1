Write-Output @"
[wagents] Session initialized.
- Main agents: wagent (default; orchestrator+architect merged) and wagent-hacker (authorized offensive security mode). Mains never call each other; only mains delegate.
- Specialists: frontend-designer, backend-engineer, security-engineer, code-reviewer, debugger, qa-engineer, research-specialist, documentation-specialist, ml-engineer, devops-engineer.
- Available slash commands: /wagents:brainstorm, /wagents:plan, /wagents:execute, /wagents:verify, /wagents:review, /wagents:debug, /wagents:taste.
- Engineering principles: Red-Green TDD, verification before completion, least privilege, zero secrets in source.
- Skills: 115 across anth/awesome/base/devops/memory/mcp/ml/obsidian/super/taste/ui-ux groups. Use the Skill tool; see skills/<name>/SKILL.md.
- Memory: agentmemory MCP is available to every agent. Save durable decisions/learnings with memory_remember; call memory_recall or memory_smart_search before re-explaining known context. codebase-memory remains for code-structure indexing (wagent owns indexing).
- All agents may use mcp-codebase-memory (query-first before scanning).
"@

