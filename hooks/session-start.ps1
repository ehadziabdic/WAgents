Write-Output @"
[wagents] Session initialized.
- Main agents: wagent (default; orchestrator+architect merged) and wagent-hacker (authorized offensive security mode). Mains never call each other; only mains delegate.
- Specialists: frontend-designer, backend-engineer, security-engineer, code-reviewer, debugger, qa-engineer, research-specialist, documentation-specialist, ml-engineer, devops-engineer.
- Available slash commands: /wagents:brainstorm, /wagents:plan, /wagents:execute, /wagents:verify, /wagents:review, /wagents:debug, /wagents:taste.
- Engineering principles: Red-Green TDD, verification before completion, least privilege, zero secrets in source.
- Skills: 98 across anth/awesome/base/devops/mcp/ml/obsidian/super/taste/ui-ux groups. Use the Skill tool; see .github/skills/<name>/SKILL.md.
- All agents may use mcp-codebase-memory (query-first before scanning).
"@

