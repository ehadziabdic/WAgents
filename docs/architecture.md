# Architecture — wagents

## Hierarchy

```text
wagent — MAIN #1 (default)                  wagent-hacker — MAIN #2 (authorized offensive only)
   cannot call wagent-hacker                    cannot call wagent
        |                                            |
        +--> FRONTEND-DESIGNER                       +--> FRONTEND-DESIGNER
        +--> BACKEND-ENGINEER                        +--> BACKEND-ENGINEER
        +--> SECURITY-ENGINEER                       +--> SECURITY-ENGINEER
        +--> CODE-REVIEWER (independent)             +--> CODE-REVIEWER (independent)
        +--> DEBUGGER                                +--> DEBUGGER
        +--> QA-ENGINEER                             +--> QA-ENGINEER
        +--> RESEARCH-SPECIALIST                     +--> RESEARCH-SPECIALIST
        +--> DOCUMENTATION-SPECIALIST                +--> DOCUMENTATION-SPECIALIST
        +--> ML-ENGINEER                             +--> ML-ENGINEER
        +--> DEVOPS-ENGINEER                         +--> DEVOPS-ENGINEER
        |
        +--> direct implementation when no specialist fits
```

Delegation rules (enforced in every agent file + `config/agents.json`):

- Only the two **main agents** delegate.
- Main agents **never call each other** — to switch lanes the user switches agents
  (offensive work needs `wagent-hacker` and its explicit target authorization).
- Specialists **never delegate**; they report back to the calling main agent.
- `wagent` absorbed the former **architect** lane (architecture decisions, ADRs, system design).

Concept:

```text
Agent
 ├── specialized instructions (.github/agents/*.agent.md)
 ├── selected skills (.github/skills/*/SKILL.md)
 ├── selected MCP tools (mcp/servers.json + config/permissions.json)
 ├── strict permissions (config/permissions.json)
 └── delegation rules (.github/agents/wagent.agent.md + wagent-hacker.agent.md, mirrored in config/agents.json)
```

## Orchestration policy

```text
1. Understand request
2. Inspect relevant project context
3. Identify task domains
4. Choose specialist agents
5. Delegate independent tasks in parallel
6. Collect outputs
7. Resolve conflicts/ambiguities
8. Implement
9. Run tests
10. Run security validation when relevant
11. Independent code review for substantial changes
12. Fix findings
13. Final verification
14. Report what changed and what was/was not verified
```

Examples:

### "Build a secure SaaS dashboard"
Delegate: frontend-designer, backend-engineer, security-engineer, qa-engineer
(wagent owns the architecture decisions itself — the architect lane was merged into wagent).
Then implementation + code-reviewer + validation.

### "Why is this page broken?"
Delegate: debugger + frontend-designer or qa-engineer if browser/UI.
Then minimal fix + regression test.

### "Should we use Framework A or B?"
Delegate: research-specialist for current evidence; wagent makes the architecture call.
Do not choose from stale knowledge.

### "Pentest our staging environment (we own it)"
Switch to the `wagent-hacker` agent. Authorization gate first (scope + target), then
the vendored claude-red skill index. `wagent` cannot delegate offensive work.

## Global vs project layer

Global (this repo) is reusable: agents, common skills, MCP definitions, routing, generic instructions, bootstrap tooling.

Project-specific config lives in each real project and may override/extend global:

```text
GLOBAL frontend-designer
        +
PROJECT frontend-designer
        =
project-specific design behavior
```

See `templates/project/` for the override pattern. Never make global defaults uncustomizable.

## Design principles

- Agents do orchestration and judgment. Reusable procedures live in `SKILL.md` skills.
- MCP provides external capabilities/data.
- Use Copilot's current custom-agent and Agent Skills mechanisms. Do not invent an incompatible parallel system.
- Prefer evidence over assumptions. Use current docs via Context7/research-specialist.
- Keep changes small and reviewable. Preserve reproducibility.
