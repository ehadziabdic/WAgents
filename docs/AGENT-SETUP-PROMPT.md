# AGENT SETUP PROMPT - paste into a fresh opencode chat on the new machine

PHASE 0 (do this by hand BEFORE opening opencode - 10 minutes):

1. Install OpenCode Desktop (it brings its own CLI):
   `winget install SST.OpenCodeDesktop`, or download the installer
   from opencode.ai. Launch it once so the background service starts.
2. Install Tailscale, log in. Ask the tailnet admin to approve your
   machine if it stays pending.
3. Install Python 3.12+, Node 22+, Git (or let install.ps1 try).
4. Clone this repo, e.g. next to your home folder.
5. `opencode auth login` (repeat per account) so your FIRST chat has
   models. Then open opencode and paste everything below the line.

NOTE ON SECRETS: this public repo ships ZERO secrets. You will create
every key yourself during setup: provider logins, Figma Bearer token,
Google Drive OAuth, Telegram bot token + your chat ID, service password.
The agent collects them in ONE ask (see action-request pattern below).

---

You are setting up the WAgents environment on a fresh Windows machine from
the WAgents-private repo cloned beside this session (./WAgents-private).

Goal: replicate the full setup so opencode, skills, agents, Telegram bot,
Drive remote, and watchers all work exactly as documented in
WAgents-private/docs/SETUP.md.

Rules:
- Never git push or commit unless I explicitly say so.
- Never expose or print secrets (tokens, passwords, keys). Use them only
  from files, never echo them to chat or logs.
- Brave only, never Chrome. Tailscale must stay the only remote path.
- Session-only operation: no scheduled tasks, no autostart entries.
- ACTION-REQUEST PATTERN: whenever you are blocked on something only I
  can do, stop and reply with exactly this shape, everything at once:
  "I am done with everything I can do alone. I need action from you:"
  followed by a numbered list where each item states WHAT to do, WHERE
  (exact clicks/paths), and WHY it cannot be automated. Never dribble
  blockers out one message at a time. Collect them and ask once.

Steps:
1. Read WAgents-private/README.md, docs/SETUP.md, and AGENTS.md fully
   before touching anything.
2. Run WAgents-private/install.ps1 from an elevated PowerShell. Report
   each numbered stage pass/fail with evidence. Fix failures before
   continuing (missing winget packages, pip errors, npm errors).
3. Work through docs/SETUP.md section 2 WITH me, one item at a time.
   Do ALL automatable items first without asking. Then use the
   ACTION-REQUEST PATTERN once to collect every manual item:
   - Provider + service secrets I must create/paste: opencode logins
     (already done in Phase 0), Figma Bearer token for
     opencode.jsonc, service password for service.json, Google Drive
     OAuth (via rclone config), Telegram bot token from @BotFather.
   - Telegram: my numeric chat ID from @userinfobot, written into
     telegram/.telegram.env as TELEGRAM_ALLOWED_CHAT_ID.
   - JupyterHub: I will paste MY Hub token, or we skip the watcher
     if I have no such server.
   - Tailscale: approve the machine if pending, confirm Private profile.
   - Telegram bot start + `.voice-target-session` must point at THIS
     session ID.
4. Verify with docs/SETUP.md section 3 and report every check pass/fail
   with concrete output. Do not claim done until all green.
5. End with a short list of what works and what still needs me.
