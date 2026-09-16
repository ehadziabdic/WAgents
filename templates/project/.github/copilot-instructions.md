# WAgents — Project Copilot Instructions

This file was created by `wagents init`. Project instructions extend, and override,
the global wagents setup. Customize everything below for this repository.

## Routing

- Architecture, integration, and cross-cutting decisions: `wagent` (main agent).
- Authorized offensive security: switch to the `wagent-hacker` agent explicitly (user-driven switch, never a delegation).
- UI/UX and frontend: `frontend-designer`
- APIs, auth, database, business logic: `backend-engineer`
- Defensive security and review: `security-engineer`
- Independent code review: `code-reviewer`
- Root-cause analysis: `debugger`
- Testing: `qa-engineer`
- Web research and docs verification: `research-specialist`
- Documentation, diagrams, slides, vaults: `documentation-specialist`
- ML/data/LLM: `ml-engineer`
- Docker, CI/CD, cloud, deployment: `devops-engineer`

## Project overrides (fill in)

- Primary stack: <languages, frameworks, versions>
- Test command: <exact command agents must run to validate changes>
- Build command: <exact command>
- Never touch without explicit approval: <paths, migrations, infra>
- Additional rules: <project conventions that override global defaults>
