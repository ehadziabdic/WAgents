# Reminders (user-requested, act on when asked)

- NOTE (standing): rclone shared client_id retires during 2026 - if
  Drive uploads fail with auth errors, create own client_id and re-run
  `rclone config`.
- NOTE (standing): Monthly private-repo sync - push new setup features
  to the private repo when user says so.
- [x] HIGH PRIORITY Portfolio Redesign DONE (tweaks may follow later).
- [x] HIGH PRIORITY CV Redesign DONE.
- [x] Harness Score baseline DONE 2026-10-07: WAgents L1 44, Private L1 41, PerfectCV L0 23 (JSONs in docs/harness-baseline-*.json). Core setup L2 57 via harness-scan.ps1. Next: gap fixes toward L2/L3.
- [ ] Startup popups: `cua-driver-serve` and `OpenClaw Gateway` tasks are still
  enabled (ACL protected, one UAC click needed). Next time the user is at the
  keyboard run
  `powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\eminha\.config\opencode\scripts\disable-login-popups.ps1`
  and approve the prompt. `-Status` checks without elevating, `-Enable` reverts,
  nothing is deleted.
- [ ] Portfolio: 3D model of me instead of photo - CONFIRMED, user
  wants a guided tool walkthrough (Avaturn/Meshy/Luma routes) before
  any build. Photo stays fallback no matter what.
