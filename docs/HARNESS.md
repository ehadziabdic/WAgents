# HARNESS PORTABILITY - what runs where

WAgents is opencode-first (it mirrors a live opencode install), with
documented adapters for Codex, DeepSeek Harness, and GitHub Copilot CLI.
Anything below marked "verify" means: checked against official docs at
time of writing, re-check with `--help` on the day you wire it, CLIs move fast.

## Portable everywhere (no changes)

- `opencode/agents/*.md` - plain markdown (`description:` + `mode:`).
- `opencode/skills/*/` - `SKILL.md` + assets folders.
- `opencode/command/` - slash commands, markdown + `$ARGUMENTS`.
- `opencode/instructions/` - per-language rules.
- `opencode/scripts/*.ps1`, `cdp-drive.js` - Windows/Node level only.
- Telegram bot core: polling, allowlist, all commands, heartbeat inbox,
  retention sweep. Only the session bridge (below) is harness-locked.

## OpenCode (base, complete)

Everything works as documented. Session bridge shells out to
`opencode run --session <ses_id> <text>`; target session ID lives in
`telegram/.voice-target-session`. MCP remotes live in
`opencode/opencode.jsonc`.

## Codex CLI (adapter documented, bridge to verify)

- **Agents/skills/commands**: Codex reads `AGENTS.md` natively and
  supports `SKILL.md`-style skills; agent fields map between TOML
  (Codex) and YAML frontmatter (Claude-style), including model aliases.
  Copy the markdown over, adjust frontmatter to TOML where Codex demands it.
- **MCP**: `~/.codex/config.toml`, one section per server; remote URLs
  carry over from `opencode.jsonc`, including remote servers.
- **Session bridge**: point `run_in_session` at the non-interactive
  runner (`codex exec`, see `codex exec --help` for session resume
  options on your version). Without it the bot falls back to
  transcribe-and-acknowledge; nothing breaks.
- **Installer**: replace the OpenCode Desktop step with the Codex CLI
  install; the rest (Tailscale, Python/Node, firewall, rclone, whisper)
  is identical.

## DeepSeek Harness / dsh (adapter documented, native bundle = future work)

dsh is a Cordis plugin runtime, not a markdown-agent host: capabilities
arrive as mounted plugins, profiles compose bundles, and user overrides
live in `$DSH_HOME/cordis.patch.yml`. There is no drop-in skill folder,
so be honest about tiers:
- **Today**: agents/skills docs work as pasted context and reference;
  MCP servers register via `cordis.patch.yml`; the `headless` profile
  (one-shot runner, no server) is the hook for scripted prompts and the
  natural target for a future `run_in_session` equivalent.
- **Future work**: a real `dsh` bundle (`package.json` `dsh` field)
  wrapping the skill set. That is a build of its own, not a copy.
- Install `dsh`, then follow the same Tailscale/Python/Node/rclone
  stages; skip anything opencode-App-shaped.

## GitHub Copilot CLI (adapter documented, bridge to verify)

- **Agents/skills**: custom agents are markdown files with YAML
  frontmatter; agent skills are folders of instructions/scripts/resources
  that load by relevance. Copy both over, keep names.
- **MCP**: user level `~/.copilot/mcp-config.json`, project level
  `.copilot/mcp-config.json`. Custom agents can reference MCP servers
  and tools; keep the per-agent scoping from the WAgents delegation map.
- **Session bridge**: use the CLI's non-interactive print mode (see
  `copilot --help` on your version) inside `run_in_session`. Fallback
  behavior is unchanged.
- **Installer**: replace OpenCode Desktop with the Copilot CLI install;
  everything else carries over.

## opencode-locked leftovers (all harnesses)

1. `WAGENTS_CONFIG` default (`~/.config/opencode`): override per host
   via env var, no code change needed.
2. `.voice-target-session` holds one session ID string per harness;
   formats differ, the file contract does not.
3. `install.ps1` stages [1]-[3] and `AGENT-SETUP-PROMPT.md` Phase 0
   assume OpenCode Desktop; swap those steps per harness above.
