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

## User global rules

- Never `git push` or `git commit` unless the user explicitly told you to in the current task.
- Always delete implementation plans (wagents/superpowers plans) automatically when the whole plan is finished, no need to ask.
- Always use `<WAGENTS-DIR>` for all wagents/superpowers documentation (specs `docs/specs/`, plans `docs/plans/`, reminders `docs/`). `<WAGENTS-DIR>` = `./.wagents` under the session root, except when the session root is the home folder, where it is `.config/opencode/.wagents`. Project sessions keep everything inside `project/.wagents/`.
- Never create git worktrees — edit files directly in the working directory.
- Never save bot/session artifacts to Downloads or other user folders. All incoming files go to `<WAGENTS-DIR>/inbox/` (single copy, no duplicates). Heartbeat JSON alerts live separately under `schedules/inbox/`.
- Always use Brave, not Chrome or any other browser, except when explicitly told otherwise.
- NEVER use em dashes (—) in any report text, thesis text, or other text meant to be copy/pasted into a report — use commas, colons, parentheses, or hyphens (-) instead. Em dashes are fine in casual chat outputs to the user.
