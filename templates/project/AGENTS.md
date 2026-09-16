# WAgents — Project Agent Instructions

This file was created by `wagents init`. It gives agents working in this repo the
wagents operating model while keeping all project-specific rules here, next to the
code they govern. Project instructions extend, and override, the global wagents setup.

## Global routing reference

| Route to | For |
|---|---|
| `wagent` (default main) | intent, architecture, routing, integration, validation |
| `wagent-hacker` (separate agent) | authorized offensive security only; user switches agents explicitly |
| `frontend-designer` | UI/UX, accessibility, frontend implementation |
| `backend-engineer` | APIs, auth, database, business logic |
| `security-engineer` | defensive security, threat modeling, scanning |
| `code-reviewer` | independent review (read-only) |
| `debugger` | root-cause analysis, minimal fixes |
| `qa-engineer` | unit/integration/E2E/browser testing |
| `research-specialist` | web research, docs verification (read-only) |
| `documentation-specialist` | docs, diagrams, slides, vaults, office formats |
| `ml-engineer` | Python/data, ML, RAG/LLM, evaluation |
| `devops-engineer` | Docker, CI/CD, cloud, deployment |
