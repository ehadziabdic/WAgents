# WAgents — Project Agent Instructions

This file was created by `wagents init`. It gives agents working in this repo the
wagents operating model while keeping all project-specific rules here, next to the
code they govern. Project instructions extend, and override, the global wagents setup.

## Global routing reference

| Route to | For |
|---|---|
| `wagent` (default main) | intent, architecture, routing, integration, validation |
| `wagent-ask` (planning) | chat-only design, specs, plans; callable by `wagent` for advanced planning |
| `cv-maintainer` | portfolio/CV sync, render, Desktop copies, Drive upload |
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
- Release workflow: when the user confirms something new is good, append it to `.config/opencode/.wagents/docs/push-ready.md` (date + what + where). It stays out of WAgents-private until push day. When the user says push, apply every open push-ready item to the private repo first, then push, then clear the file.
- Reminders hygiene: remove items from `.config/opencode/.wagents/docs/reminders.md` once they are done, no need to ask. Done means gone.
- Always use `<WAGENTS-DIR>` for all wagents/superpowers documentation (specs `docs/specs/`, plans `docs/plans/`, reminders `docs/`). `<WAGENTS-DIR>` = `./.wagents` under the session root, except when the session root is the home folder, where it is `.config/opencode/.wagents`. Project sessions keep everything inside `project/.wagents/`.
- Never create git worktrees — edit files directly in the working directory.
- Never save bot/session artifacts to Downloads or other user folders. All incoming files go to `<WAGENTS-DIR>/inbox/` (single copy, no duplicates). Heartbeat JSON alerts live separately under `schedules/inbox/`.
- Always use Brave, not Chrome or any other browser, except when explicitly told otherwise.
- Telegram notify rule: when the user says "notify me on telegram" or just "notify me" with no additional content (no custom text requested), send a Telegram message in exactly this format:
  Task done!
  http://100.106.142.44:49374/
  Mechanism (globally configured): run `C:\Users\eminha\.config\opencode\scripts\tg-send.ps1 -Text "<message>"` via shell. It reads credentials itself from `scripts/.telegram.env` (bot kept alive by the `pc-daemons-autostart` opencode plugin). Never print or edit that env file. Keep messages under 4000 chars. `tg-send.ps1 -File "<path>"` attaches a document (caption = -Text).
- Telegram CV trigger: "update my cv/portfolio" (text or transcribed voice, any session incl. the Telegram target session) → delegate to `cv-maintainer` for the full sync; it ends with the Telegram delivery + publish question itself. A later "publish it" (same conversation) → Drive upload of Desktop `Full-EU.pdf` as `CV.pdf`, then text confirmation via `tg-send.ps1`.
- NEVER remove, rewrite, or "clean up" code the user added themselves unless they explicitly tell you to. If their code conflicts with a requested behavior, stop and ask first instead of silently changing it.
- NEVER use em dashes (—) in any report text, thesis text, or other text meant to be copy/pasted into a report — use commas, colons, parentheses, or hyphens (-) instead. Em dashes are fine in casual chat outputs to the user.
- Permissions: this setup runs fully trusted on this machine. Every session (TUI, `opencode run`, Telegram voice/text via the bot, MCP-driven runs) is expected to execute read/edit/shell/skill/subagent/webfetch/websearch/MCP tools without approval prompts. If a tool ever reports that shell or permission access is blocked, treat it as a misconfiguration: check that global `opencode.jsonc` `permissions` still allows everything and that `scripts/telegram-pc-bot.py` still passes `--auto` to `opencode run`. Never ask the user for permission to run commands that this rule covers.
- About me: whenever any agent needs info about the user (background, links, handles, education, portfolio URL), check `.config/opencode/aboutme.md` FIRST (sits next to this file) and never ask for anything recorded there. That file holds PII and NEVER goes into any repo, sync, screenshot, or log.
