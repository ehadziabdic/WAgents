# OpenCode home setup (WAgents core)

Personal portable OpenCode configuration: agents, skills, MCP servers,
Telegram remote, and helper scripts. Private single-machine setup with
shared keys across the owner's devices (secrets live inline in
`opencode.jsonc` by design — see Privacy below).

## Layout

- `AGENTS.md` — global agent instructions and routing table (start here)
- `aboutme.md` — user identity/links reference (PII, local only)
- `agents/` — `wagent` (Build), `wagent-ask` (planning), 11 specialists
- `skills/` — capability library (advertised subset + wake-on-demand rest)
- `instructions/` — global coding standards (python/react/security/...)
- `commands/` + `command/` — slash-command templates
- `opencode.jsonc` — MCP servers, permissions (allow-all, trusted box),
  provider, instructions list
- `opencode.json` — model, provider keys, plugin registration
- `opencode-mem.jsonc` — persistent memory (local Turso, keyless capture)
- `cli.json` — TUI-only preferences
- `plugins/pc-daemons-autostart.js` — keeps the Telegram bot alive
- `scripts/` — `telegram-pc-bot.py`, `tg-send.ps1`, `cv-render.ps1`,
  `harness-scan.ps1`, `screenshot-*.ps1`, `tg-send.ps1 -File` for docs
- `schedules/` — heartbeat/watcher inbox
- `.wagents/` — push-ready queue, reminders, harness reports/plans
- `biome.json` / `pyproject.toml` — formatter+lint for first-party
  `plugins/*.js`, `scripts/*.js`, `scripts/telegram-pc-bot.py`

## Everyday commands

- `cv-render.ps1` — render all 4 CV PDFs + tests + Desktop copies
- `tg-send.ps1 -Text/-File` — Telegram message/document as the bot
- `harness-scan.ps1` — Harness Score on this setup → `.wagents/`
- `opencode mcp list` — MCP server states (wake group stays disabled
  until `use <name> mcp`)

## Privacy

`aboutme.md`, `scripts/.telegram.env`, `opencode.json(c)` keys and
`.wagents/` contents are PII/secrets: never commit to a public repo,
never paste into logs or screenshots.
