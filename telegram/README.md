# Telegram integration (wagents_bot)

Session-only listener: answers while the PC is awake and the bot process runs.
No scheduled tasks, no inbound ports (long polling).

## Files

- `telegram-pc-bot.py` - the bot. Reads `.telegram.env` next to itself.
  Everything else resolves via `WAGENTS_CONFIG` env var (default
  `~/.config/opencode`): scripts, schedules/inbox, .wagents/inbox.
- `.telegram.env` - `OPENCODE_TELEGRAM_TOKEN` + `TELEGRAM_ALLOWED_CHAT_ID`
  (allowlist, single user). Never commit anywhere public.
- `.telegram.env.example` - placeholder template.
- `.voice-target-session` - session ID that voice/free-text messages run in.
  Update it whenever a new main chat starts (paste the new `ses_...` ID).
- `tg-send.ps1` - operator tool: send a Telegram message from PowerShell.
  Usage: `tg-send.ps1 -Text "hello"`.

## Commands

/shot /status /ls /get /drive /zip /unzip /clip /upload /photo /voice
/voice (typed) /help. Plain text runs in the target chat session.

## Run

`python telegram/telegram-pc-bot.py` (needs requirements installed).
