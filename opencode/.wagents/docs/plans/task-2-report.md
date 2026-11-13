# Task 2 Report: Playwright isolated + Brave attach

Status: BLOCKED (scripts created per plan, debug port 9333 NOT open)

## Files created
- C:\Users\eminha\.config\opencode\scripts\brave-debug-launch.ps1 (exact plan content, Step 3)
- C:\Users\eminha\.config\opencode\scripts\test-task2.ps1 (exact plan content, Step 1)
- No other files created or modified. No git, no worktrees, no secrets.

## Test output
1. `brave-debug-launch.ps1` output:
   - `WARNING: TCP connect to (127.0.0.1 : 9333) failed`
   - `TcpTestSucceeded: False`
2. `test-task2.ps1` output:
   - `throw "Brave debug port 9333 not open"`, exit 1. No TASK2-OK.

## What happened
- Brave was already running WITHOUT the --remote-debugging-port flag (17 brave processes live, main window "(2) Instagram Messages - Brave").
- Launching again with the plan's exact args (`--remote-debugging-port=9333 --user-data-dir="<same default User Data>"`) did NOT open a second debuggable instance. Chrome-family browsers reuse the running process when the user-data-dir matches, so the new flags are ignored and port 9333 stays closed. This is the exact first-try failure mode the task description predicted.

## Concerns / next step options (needs parent decision, NOT done here)
- Option A (recommended for Task 2 retry): close all Brave windows first, then re-run brave-debug-launch.ps1 so the debug flag takes effect on a fresh process. Risk: closes user's current tabs (Instagram Messages window).
- Option B: use a SEPARATE user-data-dir (e.g. `%LOCALAPPDATA%\BraveSoftware\Brave-Browser-RemoteDebug`) for the debuggable instance, leaving the main Brave untouched. Deviation from plan text, but gives a true second instance on port 9333 with no disruption.
- Playwright MCP verify steps (browser_navigate, browser_snapshot, screenshot to .out/pw-test.png, preview) were not attempted since port 9333 is closed.
- Fallback (focus-window.ps1 + screenshot-desktop.ps1 from Task 1) remains available and untested in this task.

## Fix round (2026-09-23, binding ruling applied)
- Changed `brave-debug-launch.ps1` to use SEPARATE data dir `C:\Users\eminha\.config\opencode\scripts\.brave-debug-profile` (side-by-side with main Brave, no disruption):
  - `$dataDir = "C:\Users\eminha\.config\opencode\scripts\.brave-debug-profile"` with auto-create, launch args `--remote-debugging-port=9333 --user-data-dir="<separate>" --no-first-run about:blank`.
- `brave-debug-launch.ps1` output: `TcpTestSucceeded: True`.
- `Test-NetConnection 127.0.0.1:9333` output: `TcpTestSucceeded: True, RemoteAddress 127.0.0.1, RemotePort 9333`.
- `http://127.0.0.1:9333/json/version` reachable, Browser `Chrome/153.0.8010.53`, ws debugger URL present.
- `test-task2.ps1` output: `TASK2-OK`, exit 0.
- Main user Brave was NOT closed.
- Status: DONE.
