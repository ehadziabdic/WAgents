# AGENT SETUP PROMPT - paste into a fresh opencode chat on the new machine

PHASE 0 (do this by hand BEFORE opening opencode - 10 minutes):

1. Install OpenCode Desktop (it brings its own CLI):
   `winget install SST.OpenCodeDesktop`, or download the installer
   from opencode.ai. Launch it once so the background service starts.
2. Install Tailscale, log in. Ask the tailnet admin to approve your
   machine if it stays pending.
3. Install Python 3.12+, Node 22+, Git (or let install.ps1 try).
4. Clone this repo, e.g. next to your home folder.
5. Fill the placeholder credentials you have, or let `opencode auth
   login` create them after the first launch. The public repo ships
   placeholders only: `local-share/*.json`, `telegram/.telegram.env`,
   `rclone/rclone.conf`, and the provider tokens in
   `opencode/opencode.json`. Then open opencode and paste everything
   below the line. The installer also sets up OpenCode Browse (agents
   in your real Brave) automatically; it opens one browser window for a
   one-click confirm. Hex (voice dictation) is optional and is not
   installed automatically; install it by hand with
   `irm https://anoma.ly/hex/install-windows.ps1 | iex` if you want it.
6. Optional: the `[WAgent] Unrestricted` prompt collection, if you have
   access to it. `install.ps1` installs the resolver and model map but
   not the prompts. Pass the URL when you run it
   (`.\install.ps1 -JailbreaksRepo <url>`), or clone it into
   `%USERPROFILE%\.config\opencode\jailbreaks`. Skip it and that agent
   simply answers STATUS=no-match.

NOTE ON CREDENTIALS: this public repo contains no live keys. Use your
own provider accounts, Telegram bot, Drive remote, and JupyterHub
token. Anything in `local-share/` is a template until you replace it.

---

You are setting up the WAgents environment on a fresh Windows machine from
the WAgents repo cloned beside this session (./WAgents).

Goal: replicate the full setup so opencode, skills, agents, Telegram bot,
Drive remote, and watchers all work exactly as documented in
WAgents/docs/SETUP.md.

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
1. Read WAgents/README.md, docs/SETUP.md, and AGENTS.md fully
   before touching anything.
2. Run WAgents/install.ps1 from an elevated PowerShell. Report
   each numbered stage pass/fail with evidence. Fix failures before
   continuing (missing winget packages, pip errors, npm errors).
3. Work through docs/SETUP.md section 2 WITH me, one item at a time.
   Do ALL automatable items first without asking. Then use the
   ACTION-REQUEST PATTERN once to collect every manual item:
   - Telegram: my Telegram numeric ID is MINE, not a template value. I
     will get it from @userinfobot and you will write it into
     telegram/.telegram.env AND the live copy as TELEGRAM_ALLOWED_CHAT_ID.
   - JupyterHub: I will paste MY OWN Hub token, or we skip the watcher
     if I have no ETF account.
   - Tailscale: approve the machine if pending, confirm Private profile.
   - Telegram bot start + `.voice-target-session` must point at THIS
     session ID (never a stale one).
4. Verify with docs/SETUP.md section 3 and report every check pass/fail
   with concrete output. Do not claim done until all green.
5. End with a short list of what works and what still needs me.
