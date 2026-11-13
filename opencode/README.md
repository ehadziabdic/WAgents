# OpenCode home setup (WAgents core)

Personal portable OpenCode configuration: agents, skills, MCP servers,
Telegram remote, and helper scripts. Private single-machine setup with
shared keys across the owner's devices (secrets live inline in
`opencode.jsonc` by design — see Privacy below).

## Layout

- `AGENTS.md` — global agent instructions and routing table (start here)
- `aboutme.md` — user identity/links reference (PII, local only)
- `agents/` — `[WAgent] Build` (Build), `[WAgent] Plan` (planning), 13 specialists;
  `[WAgent] Unrestricted` is a main agent, user-selected only
- `skills/` — capability library (advertised subset + wake-on-demand rest)
- `instructions/` — global coding standards (python/react/security/...)
- `commands/` + `command/` — slash-command templates
- `opencode.json` — the single config (JSONC; `opencode.jsonc` is merged in): model, provider keys, plugin registration, MCP servers (always-on + wake-on-demand), permissions (allow-all, trusted box), instructions list. `browse` (Brave driver, MCP) was added 2026-11-10
- `opencode-mem.jsonc` — persistent memory (local Turso, keyless capture)
- `cli.json` — TUI-only preferences
- `.wagents/secrets/opencode-accounts.json` — private backup of the 4
  OpenCode provider accounts (runtime store is `opencode.db`)
- `plugins/pc-daemons-autostart.js` — starts the Telegram bot only when
  `scripts/.autostart.json` says `telegramBot: true`
- `scripts/` — `telegram-pc-bot.py`, `autostart-control.ps1`,
  `tg-send.ps1`, `cv-render.ps1`, `harness-scan.ps1`,
  `screenshot-*.ps1`, `tg-send.ps1 -File` for docs,
  `resolve-jailbreak.ps1` + `jailbreak-model-map.json` for `[WAgent] Unrestricted`
- `jailbreaks/` — separate git repo of model prompts, never mirrored here
  (ignored); `[WAgent] Unrestricted` loads exactly one model-matched file from it.
  `install.ps1` does not ship these: install with `-JailbreaksRepo <url>`
  or clone into `~/.config/opencode/jailbreaks` by hand
- `schedules/` — heartbeat/watcher inbox (drained by the bot poll loop)
- `.wagents/` — push-ready queue, reminders, harness reports/plans
- `biome.json` / `pyproject.toml` — formatter+lint for first-party
  `plugins/*.js`, `scripts/*.js`, `scripts/telegram-pc-bot.py`

## Everyday commands

- `autostart-control.ps1 -Status|-Enable|-Disable` — one switch for the
  Telegram bot, Hermes gateway and OmniRoute login entries. OpenChamber
  is never touched: it stays in HKCU Run with `--background` and starts
  the OpenCode server for phone access. The Telegram bot is ON at login by
  default; Hermes and OmniRoute stay parked. Add `-TelegramOnly` to toggle
  only the bot and leave the other parked entries alone.
- `pc-commands.ps1 <verb>` - pinned PC surface used by agents and the bot:
  `stremio-start|stop|status`, `telegram-start|stop|status`, `health`,
  `training-status`, `docker-status`, `autostart-status`, `notify`.
- `stremio-control.ps1 -Action Start|Stop|Status` - non-interactive twin of
  `Documents\scripts\Stremio Server Starter.bat` (Docker compose + gist).
- `cv-render.ps1` — render all 4 CV PDFs + tests + Desktop copies
- `tg-send.ps1 -Text/-File` — Telegram message/document as the bot
- `harness-scan.ps1` — Harness Score on this setup → `.wagents/`
- `opencode mcp list` — MCP server states (wake group stays disabled
  until `use <name> mcp`)

## Privacy

`aboutme.md`, `scripts/.telegram.env`, `opencode.json(c)` keys and
`.wagents/` contents are PII/secrets: never commit to a public repo,
never paste into logs or screenshots.
