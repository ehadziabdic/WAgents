# HARNESS PORTABILITY - what runs where

WAgents-private is opencode-first (it mirrors a live opencode install).
Almost everything is plain markdown + PowerShell and ports freely; the
opencode-locked seams are listed here so Codex/Claude/Copilot adapters
know exactly what to replace. See also: the public WAgents repo, which
is the multi-provider edition.

## Portable as-is (no changes)

- `opencode/agents/*.md` - agent definitions are plain markdown with
  `description:` + `mode:` frontmatter. Claude Code (`agents/*.md`),
  Codex (`AGENTS.md` + skills), Copilot (`.github/agents/*.agent.md`)
  all consume this shape with trivial renames.
- `opencode/skills/*/` - every skill is `SKILL.md` + assets. Same shape
  across harnesses.
- `opencode/command/` - 7 slash commands, markdown + `$ARGUMENTS`.
- `opencode/instructions/` - per-language rules, portable.
- `opencode/scripts/*.ps1`, `cdp-drive.js` - Windows/Node level, no
  harness dependency. Only Brave + PowerShell required.
- Telegram bot core: polling, allowlist, /shot /status /ls /get /drive
  /zip /unzip /clip /upload /photo /help, heartbeat inbox, retention
  sweep. No harness in these paths.

## opencode-locked seams (one adapter each)

1. **Session bridge** (`telegram/telegram-pc-bot.py`, `run_in_session`):
   shells out to `opencode run --session <ses_id> <text>`. Port = swap
   that one function: Codex `codex exec resume <id>`, Claude
   `claude -p --resume`, Copilot equivalent. Without it the bot falls
   back to transcribe-and-acknowledge (already implemented, nothing breaks).
2. **Session IDs** (`.voice-target-session`, `ses_...`): opencode format.
   Each harness has its own; the file holds one string on purpose.
3. **MCP config** (`opencode/opencode.jsonc` remotes): translate URLs +
   auth into the client's MCP file (`.mcp.json`, `config.toml`,
   `.vscode/mcp.json`). Server list itself is standard.
4. **Installer + setup prompt**: `install.ps1` stages [1]-[3] and
   `docs/AGENT-SETUP-PROMPT.md` Phase 0 assume OpenCode Desktop.
   Port = replace those steps with the client's install + session flow.
5. **WAGENTS_CONFIG default** (`~/.config/opencode`): override per host
   via env var, already supported, no code change needed.
