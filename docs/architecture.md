# Architecture — wagents

## Layout conventions

wagents deliberately follows the superpowers model where it applies and extends it where a
personal-use Agent OS needs more. Verified against `obra/superpowers` upstream
(tree `b36e0829c6d0140e93cfef2ca599b1b07d4a7797`):

| Convention | superpowers | wagents |
|---|---|---|
| Repository root is the plugin | yes (`skills/`, `hooks/`, `scripts/`, `docs/`, `tests/` at root) | same |
| Marketplace manifest in a dot dir | `.claude-plugin/marketplace.json` (+ per-provider dirs like `.cursor-plugin/`, `.hermes-plugin/`) | `.claude-plugin/marketplace.json`, `.github/plugin/marketplace.json` (Copilot), `.agents/plugins/marketplace.json` (Codex) |
| `plugin.json` lives inside the manifest dir | yes (`.claude-plugin/plugin.json`) | mirrored (`.claude-plugin/plugin.json` synced from root `plugin.json` by `scripts/build-plugin.mjs`; the root copy also serves Agent Plugins 1.0 consumers — Copilot, Antigravity, Hermes) |
| Skills at `skills/<name>/SKILL.md` | yes | same, plus frontmatter validation and a registry (`config/skills.json`) |
| Hooks at `hooks/` wired via `hooks/hooks.json` | yes | same, with a Windows `run-hook.cmd` polyglot wrapper and the vendored `hooks/agentmemory/` lifecycle scripts |
| Per-provider adapter dirs | `.cursor-plugin/`, `.devin-plugin/`, `.kimi-plugin/`, `.opencode/`, `.pi/`, … | not needed — the seven supported providers install through the marketplace manifests, direct plugin install, the CLI, or provider-native routes (`config/providers.json`) |

wagents additions that superpowers does not have (deliberate, personal-use scope):
`agents/` (first-class multi-agent hierarchy), `instructions/`, `commands/` (packaged
`/wagents:*` slash commands), `config/` (registries: agents, skills, permissions,
providers, external dependencies), `mcp/` (auditable server catalogue), `bin/` (the
cross-platform `wagents` CLI), `templates/project/`, and `manifest.json` entrypoints.

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
 ├── specialized instructions (agents/*.agent.md)
 ├── selected skills (skills/*/SKILL.md)
 ├── selected MCP tools (mcp/servers.json + config/permissions.json)
 ├── strict permissions (config/permissions.json)
 └── delegation rules (agents/wagent.agent.md + wagent-hacker.agent.md, mirrored in config/agents.json)
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
