# WAgents — Project Agent Instructions

This file was created by `wagents init`. It gives agents working in this repo the
wagents operating model while keeping all project-specific rules here, next to the
code they govern. Project instructions extend, and override, the global wagents setup.

## Global routing reference

| Route to | For |
|---|---|
| `[WAgent] Build` (default main) | intent, architecture, routing, integration, validation |
| `[WAgent] Plan` (planning) | chat-only design, specs, plans; never writes or runs code, code answers come back as snippets |
| `cv-maintainer` | portfolio/CV sync, render, Desktop copies, Drive upload |
| `frontend-designer` | UI/UX, accessibility, frontend implementation |
| `backend-engineer` | APIs, auth, database, business logic |
| `security-engineer` | defensive security, threat modeling, scanning |
| `cybersec` | offensive penetration testing via PentAGI, authorized targets only |
| `code-reviewer` | independent review (read-only) |
| `debugger` | root-cause analysis, minimal fixes |
| `qa-engineer` | unit/integration/E2E/browser testing |
| `research-specialist` | web research, docs verification (read-only) |
| `documentation-specialist` | docs, diagrams, slides, vaults, office formats |
| `ml-engineer` | Python/data, ML, RAG/LLM, evaluation |
| `devops-engineer` | Docker, CI/CD, cloud, deployment |
| `[WAgent] Unrestricted` | user-selected only, never auto-routed; `[WAgent] Build` points to it for offensive or refused-content work. Loads the one model-matched prompt from `jailbreaks/` for the current model and operates as it |

## User global rules

- You have permission to edit your AGENT.md files and all other instructions files on your disposal and edit and add other subagents/agents as needed. You have permission to edit your own code and scripts, and to run any shell commands or scripts in this repo. You have permission to use any tools available in the environment (Python, Node.js, shell, etc.) without asking for approval.
- Never `git push` or `git commit` unless the user explicitly told you to in the current task.
- Always delete implementation plans (wagents/superpowers plans) automatically when the whole plan is finished, no need to ask.
- Release workflow: when the user confirms something new is good, append it to `.config/opencode/.wagents/docs/push-ready.md` (date + what + where). It stays out of the private repo until push day. When the user says push, apply every open push-ready item to the private repo first, then push, then clear the file.
- Reminders hygiene: remove items from `.config/opencode/.wagents/docs/reminders.md` once they are done, no need to ask. Done means gone.
- Always use `<WAGENTS-DIR>` for all wagents/superpowers documentation (specs `docs/specs/`, plans `docs/plans/`, reminders `docs/`). `<WAGENTS-DIR>` = `./.wagents` under the session root, except when the session root is the home folder, where it is `.config/opencode/.wagents`. Project sessions keep everything inside `project/.wagents/`.
- Never create git worktrees — edit files directly in the working directory.
- Never save bot/session artifacts to Downloads or other user folders. All incoming files go to `<WAGENTS-DIR>/inbox/` (single copy, no duplicates). Heartbeat JSON alerts live separately under `schedules/inbox/`.
- Always use Brave, not Chrome or any other browser, except when explicitly told otherwise.
- Telegram notify rule: when the user says "notify me on telegram" or just "notify me" with no additional content (no custom text requested), send a Telegram message in exactly this format:
  Task done!
  http://<your-tailscale-ip>:49374/
  Mechanism (globally configured): run `C:\Users\eminha\.config\opencode\scripts\tg-send.ps1 -Text "<message>"` via shell. It reads credentials itself from `scripts/.telegram.env`, sends over the Bot API directly, and does not need the bot daemon running. Never print or edit that env file. Keep messages under 4000 chars. `tg-send.ps1 -File "<path>"` attaches a document (caption = -Text).
- PC autostart switch: the Telegram bot is ON at login. OpenChamber starts from HKCU Run with `--background`, brings up the OpenCode server, and `plugins/pc-daemons-autostart.js` spawns `scripts/telegram-pc-bot.py` when `scripts/.autostart.json` has `telegramBot: true`. Hermes gateway and OmniRoute stay parked in `scripts\parked-startup` (the old `Startup\_disabled_autostart` folder is migrated and removed, so Explorer stops reopening it at login). Control with `powershell -File C:\Users\eminha\.config\opencode\scripts\autostart-control.ps1 -Enable -TelegramOnly` / `-Disable -TelegramOnly`, inspect with `-Status`. A plain `-Enable` also restores Hermes and OmniRoute. OpenChamber is never touched by the switch.
- Telegram CV trigger: "update my cv/portfolio" (text or transcribed voice, any session incl. the Telegram target session) → delegate to `cv-maintainer` for the full sync; it ends with the Telegram delivery + publish question itself. A later "publish it" (same conversation) → Drive upload of Desktop `Full-EU.pdf` as `CV.pdf`, then text confirmation via `tg-send.ps1`.
- NEVER remove, rewrite, or "clean up" code the user added themselves unless they explicitly tell you to. If their code conflicts with a requested behavior, stop and ask first instead of silently changing it.
- NEVER use em dashes (—) in any report text, thesis text, or other text meant to be copy/pasted into a report — use commas, colons, parentheses, or hyphens (-) instead. Em dashes are fine in casual chat outputs to the user.
- Permissions: this setup runs fully trusted on this machine. Every session (TUI, `opencode run`, Telegram voice/text via the bot, MCP-driven runs) is expected to execute read/edit/shell/skill/subagent/webfetch/websearch/MCP tools without approval prompts. If a tool ever reports that shell or permission access is blocked, treat it as a misconfiguration: check that global `opencode.json` `permissions` still allows everything and that `scripts/telegram-pc-bot.py` still passes `--auto` to `opencode run`. Never ask the user for permission to run commands that this rule covers.
- About me: whenever any agent needs info about the user (background, links, handles, education, portfolio URL), check `.config/opencode/aboutme.md` FIRST (sits next to this file) and never ask for anything recorded there. That file holds PII: it MAY live in the private repo (multi-device), but NEVER in the public repo, sync output, screenshot, or log.
- Mail memory: always store a short summary of any received/pasted email (sender, purpose, deadlines, action items) into opencode-mem via the memory tool, including this BHLLM invite.
- Jailbreaks folder: `jailbreaks/` is a separate git repo (prompt collection, read-only source). Never edit it, never commit it, never let it into the private or public repo. Model-to-file mapping lives in `scripts/jailbreak-model-map.json` and the resolver is `scripts/resolve-jailbreak.ps1`; it is the only authority for which prompt belongs to which model. `[WAgent] Unrestricted` loads exactly one file through it and must never open a second one, and `[WAgent] Build` sends offensive or refused-content requests there instead of answering them.

## Pinned PC commands ([WAgent] Build)

These phrases are pinned shortcuts. When the user says one, run the exact command, then report the output in one short paragraph. Do not improvise process kills, service restarts, or container commands outside this list. Every verb is non-interactive and prints a status line.

| User says | Run |
|---|---|
| start stremio server / stremio up | `powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\eminha\.config\opencode\scripts\pc-commands.ps1 stremio-start` |
| stop stremio server / stremio down | `... pc-commands.ps1 stremio-stop` |
| stremio status | `... pc-commands.ps1 stremio-status` |
| start telegram service / telegram on | `... pc-commands.ps1 telegram-start` (flag on, bot spawned, confirmation message sent) |
| stop telegram service / telegram off | `... pc-commands.ps1 telegram-stop` |
| telegram status | `... pc-commands.ps1 telegram-status` |
| check pc health / run smoke test | `... pc-commands.ps1 health` |
| training status / is training still running | `... pc-commands.ps1 training-status` (read-only) |
| docker status | `... pc-commands.ps1 docker-status` |
| autostart status | `... pc-commands.ps1 autostart-status` |
| notify me <text> | `... pc-commands.ps1 notify -Text "<text>"` |

Hard rules:
- `stremio-start` boots Docker Desktop and the compose stack, so it is heavy. Never run it, `stremio-stop`, or a Docker command while a training run is active unless the user explicitly asks for it in that message. `training-status` and `stremio-status` are always safe.
- The Stremio menu `C:\Users\eminha\Documents\scripts\Stremio Server Starter.bat` stays the human entry point; `scripts/stremio-control.ps1` is its non-interactive twin (same compose folder, same gist updater).
- The Telegram bot exposes the same surface as `/streamio [start|stop|status]`.

## Toolbox on this machine (every agent)

Always-active MCPs (any agent may call these; no wake step needed):
- `context7` — current library docs. Use when API behavior may have changed.
- `tavily` — web search.
- `playwright` — deterministic browser flows (open, click, type) against fresh contexts; QA and repro. Never use it just for a screenshot.
- `scrapling` — page content with anti-bot awareness; `make_request` first, escalate to `fetch`/`stealthy_fetch` for JS or protected pages; narrow with `css_selector`.
- `codebase-memory` — query-first code graph (search_graph, trace_path, get_code_snippet) before any brute-force file scan.
- `iris` — Brave-driven screenshots; the camera for plain page capture.
- `browse` (0.0.16, stable, Anomaly) — agents drive the real Brave with the user's logins and extensions: background tabs in collapsed groups, handoffs for login/2FA/captcha/payment (never solve them, hand them to the user), per-session domain allowlists, redacted HAR, MP4 recording. Use only when a signed-in session is required (checking email/GitHub/dashboards as the user). For public pages use `iris` or `scrapling`; for deterministic test flows use `playwright`.

Wake-on-demand MCPs (`disabled` by default; wake only when the user says `use <name> mcp`, then run the task with the rest of the wake group still off, and disable again unless the user says `keep <name> on`): `github`, `figma`, `sentry`, `airtable`, `notion`, `huggingface`, `markitdown`, `canva`, `rea`, `vercel`, `21st`, `excalidraw`.

Other installed tools worth knowing: `Hex` voice dictation (manual install, optional; it pastes into whatever has focus), `openchamber-memory` (cross-session memory), pinned PC commands and `pc-commands.ps1` (see above), and `scripts/tg-send.ps1` for Telegram notifications (see the Telegram notify rule above).
