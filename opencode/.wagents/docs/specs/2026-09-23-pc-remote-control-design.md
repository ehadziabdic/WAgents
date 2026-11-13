# PC Remote Control via Tailscale + OpenCode - Design Spec

**Date:** 2026-09-23
**Status:** Approved in chat, updated 2026-09-23 with Telegram + .wagents paths
**Spec path:** `.wagents/docs/specs/2026-09-23-pc-remote-control-design.md` (user rule: always `.wagents/` not `docs/superpowers/`)
**User:** <user> on Windows (<tailscale-ip> <hostname>), iPhone via Tailscale

## Goal

Let user message OpenCode from mobile over Tailscale (existing `opencode serve` web UI) and get on-request control of the Windows PC: screenshots, Brave tab inspection, app control, file/log checks, and optional hourly training-done polling with a report.

Existing setup (verified this session):
- Tailscale up: `<tailscale-ip> <hostname> windows`, iPhone seen recently
- OpenCode desktop + `opencode-cli.exe` listening (0.0.0.0:49374 PID 5868)
- Brave at `C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe`
- Python 3.13.15, Playwright 1.63.0 available

## Requirements

1. Request-only by default. No background action unless user explicitly says "notify me when training done".
2. Scripts built on-go in `.config/opencode/scripts/` and reused when they exist.
3. Playwright MCP for web/training dashboards, plus attached real Brave support.
4. Screenshots deleted after sending if possible (best-effort, must not break mobile preview).
5. Ephemeral per-task scripts deleted on session stop if possible (optional, best-effort).
6. Hourly training-done check on demand: user can say "tell me when training done" and agent polls via Playwright/screenshot/log and reports DONE.
7. Telegram bot as second chat channel plus push for DONE alerts (user-approved addition 2026-09-23). Chat-pull via Tailscale web UI remains primary.

## Architecture

Three layers:

**Layer OS (PowerShell):** window focus, app launch, full-desktop screenshot, GPU/process/log tail. Scripts live in `.config/opencode/scripts/`, outputs in `.config/opencode/scripts/.out/`.

**Layer Web (Playwright MCP):** `browser_navigate`, `browser_snapshot`, `browser_take_screenshot`, `browser_click/type`, plus `browser.preview` to show images back to mobile. Two modes: isolated Chromium (default, no setup) and attached Brave via `--remote-debugging-port=9333` (day-1, user approved).

Polling for training-done is not true push. OpenCode cannot wake itself. Implementation uses Windows Task Scheduler entry that runs `opencode run` hourly, checks DONE condition (log pattern or epoch target or loss threshold), and writes `status.json`. Notification to phone happens on next chat poll plus Telegram push once Telegram is configured. This limitation must be in user docs.

**Layer Telegram (Telegraf/Python bot on PC):** long-polling bot using BotFather token, allowlist to user chat_id only, forwards messages to `opencode run` and returns output + screenshots. Runs as scheduled task at logon. Token stored in env var / untracked config file, never in repo.

## Components

### 1. scripts/ toolkit (persistent core + ephemeral tmp)

- Location: `C:\Users\eminha\.config\opencode\scripts\`
- Core (kept): `screenshot-desktop.ps1`, `focus-window.ps1`, `open-app.ps1`, `gpu-status.ps1`, `tail-log.ps1`, `cleanup-out.ps1`
- Ephemeral: `tmp-*.ps1` per one-off request, plus `.out/*.png` screenshots
- Cleanup rule: after `browser.preview` succeeds, schedule delete of that `.png` after 10 min (or on next cleanup run) so mobile has time to load. On session stop, delete `tmp-*.ps1` and `.out/*` older than 24h. Best-effort, logged, never fail the main task if delete fails.

### 2. Playwright + Brave attach

- Isolated mode: no config, works immediately for localhost/TensorBoard/WandB URLs.
- Attached mode (user approved main profile): Brave launched once with `--remote-debugging-port=9333` on main `User Data`. Requires one Brave restart. Debug side-profile retired.
- Fallback: if attach fails, use OS screenshot of Brave window via focus-window + screenshot-desktop.

### 3. Training watcher (opt-in polling)

- Trigger phrase: "notify me when training done" with DONE definition (example: `epoch >= 50` or log contains `Training complete` or `val_loss < 0.1`).
- Stores watch in `.config/opencode/schedules/<check_name>/watch.json` (standardized, not training-only; example `training_check/`, future `download_check/`). Each folder holds `watch.json`, `watch.log`, training/log file. Template in `schedules/_template/`.
- Checker `check-training.ps1` reads log file and/or Playwright snapshot text and/or screenshot, outputs DONE/NOT-DONE + evidence.
- Scheduler: Windows Scheduled Task `OpenCodeTrainingWatch` hourly, action `opencode run --prompt "check training watch"`. Result appended to `.watch.log`. User sees DONE on next mobile message. Telegram push once Telegram bot is configured (preferred over ntfy.sh).

### 4. Telegram control + notify (new)

- Bot created via BotFather, token in `%OPENCODE_TELEGRAM_TOKEN%` or `.config/opencode/scripts/.telegram.env` (untracked, not committed).
- Bot script `telegram-pc-bot.py` (Python + httpx, long polling, no inbound firewall): allowlist `TELEGRAM_ALLOWED_CHAT_ID`, commands `/shot` (desktop screenshot), `/brave <url>` (snapshot), `/status` (GPU + training log tail), `/done <pattern>` (arm watcher), free text forwarded to `opencode run`.
- Screenshots sent via Telegram `sendPhoto`, then local `.png` deleted after Telegram confirms success (same 10-min grace rule as web preview, but delete can be immediate after Telegram `file_id` returned).
- Security: reject all non-allowlisted chat_ids, no secrets in chat logs, Tailscale not needed for Telegram (uses Telegram cloud), rate-limit commands.

## Data flow

Mobile (Tailscale, <tailscale-ip>:port) -> opencode serve web UI -> main agent -> shell (.ps1) and/or Playwright MCP -> file in `.out/` -> `browser.preview` -> user sees image on phone -> cleanup job deletes `.png` after grace period.

## Error handling

- Locked Windows session or minimized Brave: screenshot may be black. Report "screen locked, unlock via RDP once" and fall back to log-file status.
- Brave attach port busy or not launched with flag: fall back to isolated mode + OS screenshot, with one-line fix instruction.
- Preview-before-delete: never delete before preview returns success. Keep last screenshot if preview fails.
- Scheduler missing or PC asleep: watcher reports STALE with last-check timestamp.

## Testing

- Test 1: OS screenshot round-trip (run script, preview, verify file deleted after 10 min).
- Test 2: Focus Brave + snapshot a known URL (example.com) via isolated Playwright.
- Test 3: Attached Brave list tabs (requires debug shortcut launched).
- Test 4: Watcher dry-run on dummy log containing DONE marker.
- Mobile acceptance: all four triggered from iPhone over Tailscale web UI.

## Global constraints

- Never git push or commit unless user explicitly says so in current task (user global rule overrides spec tooling defaults, so spec file is written but not committed).
- Never create git worktrees, edit directly in working directory.
- No secrets in scripts or logs. Tailscale-only exposure for serve.
- Destructive actions need explicit per-request approval.

## Open decisions for plan phase

- Exact DONE definition per training job (log path + pattern).
- Telegram BotFather token + allowed chat_id (user provides during build).
- Grace period for screenshot delete (confirmed 10 min).

## Build log 2026-09-23 evening
- Firewall: Public rules disabled, Private enabled (verified).
- Telegram bot: /shot /status /ls /get (home-jailed, 45MB cap), session-only.
- JupyterHub API verified; watcher schedules/jupyter_crash/check-jupyter.ps1 reports NO-SERVER-RUNNING when idle.
- rclone v1.75.1 installed; Drive remote OAuth pending user click.

