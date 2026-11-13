# PUSH-READY - confirmed-good additions awaiting next private release

Rule: when the user confirms something new is good, append it here with
date + what + where it lives. On push day, apply each item to
the private repo, then clear this file. Nothing here is in the private
repo yet by design.

(Pushed 2026-10-10 to private@3d39786 and public@20007b4 - queue cleared.)

## 2026-11-10 - PC command surface, Telegram autostart, /streamio

(Also: Hex voice dictation reviewed and found already installed on the
machine, stable 3.3.0; OpenCode Browse reviewed, approved, and installed
2026-11-10 - see the Browse entry at the bottom.)

New files (live in `.config/opencode`, not copied to the private repo yet):
- `scripts/pc-commands.ps1` - pinned verb dispatcher: `stremio-start|stop|status`,
  `telegram-start|stop|status`, `health`, `training-status`, `docker-status`,
  `autostart-status`, `notify`. Agents and the Telegram bot both call it.
- `scripts/stremio-control.ps1` - non-interactive twin of
  `Documents\scripts\Stremio Server Starter.bat`: `-Action Start|Stop|Status`,
  docker compose up/down, 15 s tunnel wait, `update-gist.ps1`.
- `scripts/disable-login-popups.ps1` - one-click (one UAC prompt) enable/disable
  of the two ACL-protected logon tasks that flash console windows at boot:
  `cua-driver-serve` and `OpenClaw Gateway`. `-Status` never elevates, `-Enable`
  restores them, nothing is deleted.

Changed files:
- `scripts/autostart-control.ps1` - new `-TelegramOnly` switch so `-Enable` /
  `-Disable` can toggle only the bot and leave Hermes/OmniRoute parked; parked
  entries now live in `scripts/parked-startup`, and the old
  `Startup\_disabled_autostart` folder is migrated and removed because Explorer
  reopened it at every login.
- `plugins/pc-daemons-autostart.js` - validates the pidfile against the real
  process command line, so a recycled Windows PID cannot skip the bot after a
  reboot.
- `scripts/telegram-pc-bot.py` - new `/streamio [start|stop|status]` handler with
  an async PowerShell runner; fixed the `/status` branch that sat unreachable
  after `/screen`; help text updated.
- `AGENTS.md` - new "Pinned PC commands ([WAgent] Build)" section; autostart bullet now
  documents the Telegram bot starting at login.
- `README.md` - autostart and command-surface sections updated.

Machine state (not mirrored): `scripts/.autostart.json` now has `telegramBot: true`.

Already in the private working tree, staged 2026-11-10 and not committed:
- 15 skill files with dead `../docs/` and stale sibling link fixes (77 references
  across 12 `devops-*` skills, plus `base-design-references` and
  `think-delegate`). The same edits exist in the public working tree, together
  with the earlier `install.ps1` and `verify-release.ps1` changes.

On push day: copy the three new scripts, apply the four changed files, leave
`.autostart.json` out of the repo, then commit the staged skill fixes.

## 2026-11-10 - OpenCode Browse (real-Brave agent driver)

Machine state (not mirrored): `browse` 0.0.16 stable installed to
`%USERPROFILE%\.local\bin\browse.exe` via the official
`opencode.ai/browse/install.ps1` (downloaded, reviewed, SHA-256 checked).
Chrome Web Store extension paired with Brave (id `brave-eminh`, relay on
`127.0.0.1:19988`, self-updates from Anomaly's release service).
Live `opencode.json` gained the `mcp.servers.browse` entry
(`type: local`, `OPENCODE_BROWSER_RUNTIME=auto-update`).
On push day: apply the `opencode.json` merge by hand (it holds the user's
provider keys) or verify the private repo carries the same `browse` block,
then apply the `agents/[WAgent] Build.md` and `README.md` doc edits below.

Changed files:
- `agents/[WAgent] Build.md` - `browse` added to the always-active MCP group; new
  routing bullet (signed-in tasks, handoffs; `iris` for screenshots,
  `playwright` for QA flows, `scrapling` for scraping).
- `README.md` - config-layout lines corrected: `opencode.jsonc` is gone;
  `opencode.json` is the single merged config (JSONC).

## 2026-11-10 (evening) - Full config sync + Hex/Browse auto-install + new install README

Staged in the private repo, pending commit:
- Whole live config overlaid into opencode/ (robocopy /E, no purge):
  opencode.json now carries the OpenCode + OpenRouter burner keys and the
  browse MCP entry; agents/, scripts/, plugins/, skills/ synced.
  opencode.jsonc deleted (merged into opencode.json).
- install.ps1: stage 0 now installs Brave; new [5d/10] Browse stage
  (official installer, SHA-256 verified, best-effort); numbering unified
  to /10. Hex was dropped from the installer per user decision
  2026-11-10 (optional manual install, not automatic).
- README.md rewritten for the agent-driven install: paste one prompt
  (docs/AGENT-SETUP-PROMPT.md) into a fresh chat and the agent clones,
  installs and wires everything from the repo link, secrets included.
- docs/SETUP.md, docs/AGENT-SETUP-PROMPT.md, docs/HARNESS.md,
  docs/PUBLIC-RELEASE.md, AGENTS.md, opencode/README.md,
  opencode/agents/harness-tester.md: opencode.jsonc references merged to
  opencode.json; SETUP.md documents the new Hex/Browse stages and clicks.
- .gitignore: ignores scripts/.telegram-bot.pid (machine state).
Repository-superset skills kept as-is (scientific-* pack); the runaway
nested skills/brag/brag/... tree and other self-nested dupes were
excluded/removed from the repo copy only.
