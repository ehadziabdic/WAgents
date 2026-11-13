# Task 5 Report: Heartbeat engine generalization

Status: DONE (implement + compile + dry-test only, bot NOT restarted per instructions).

## Changes

1. `schedules/inbox/README.md` (new): contract doc. `*.json` get forwarded
   as `[auto] <text>` then renamed to `*.sent`; other extensions ignored.
2. `scripts/telegram-pc-bot.py`: added `INBOX` constant (schedules/inbox
   relative to script dir) and drain block after the update loop, before
   `time.sleep(1)`. Each `*.json` is parsed for `text`, sent with `[auto] `
   prefix (truncated to 4000), renamed to `*.sent`. Per-file errors log
   `INBOX-ERROR <fn>`; scan errors log `INBOX-SCAN-ERROR`. No /help change.
3. `schedules/jupyter_crash/check-jupyter.ps1`: collects status lines into
   `$lines` (same stdout as before, still printed every run so /status via
   sysinfo.ps1 is unchanged), compares joined output to `last-state.txt`.
   On ANY change (including server started/stopped) writes
   `schedules/inbox/jupyter-<yyyyMMdd-HHmmss>.json` with `{"text": ...}`
   (4000 char cap, UTF-8 no BOM) and logs `INBOX-QUEUED <file>`. First run
   writes baseline silently (no inbox emit). Healthy steady-state is silent.
4. `schedules/_template/heartbeat.md` (new): PowerShell + Python emit
   snippets, filename pattern, and the 5 rules (contract, state-change only,
   stdout stays readable, one file per event, no secrets).

## Verification (dry-test, no bot restart, no network)

- `py_compile telegram-pc-bot.py`: exit 0.
- Drain semantics in a TEMP dir (real inbox untouched): test json parsed,
  `text` extracted, non-json file ignored, file renamed to `.sent`. Pass.
- `check-jupyter.ps1` syntax via PSParser Tokenize: 0 errors.
- State-compare + inbox-write snippet in TEMP dir: change detected,
  valid `{"text": ...}` json queued, `last-state.txt` updated, temp dir
   removed. Pass.
- Cleanup confirmed: `schedules/inbox/` holds only README.md; no
  `last-state.txt` created yet (first real watcher run will baseline
  silently); no temp dirs or test json files remain.

## Notes for orchestrator

- Bot was NOT restarted; Task 5 code goes live on next restart. Verify with
  a test inbox file after restart (write one, confirm delivery + `.sent`
  rename, then delete test files).
- Reviewers: `jail()` is untouched; inbox path is fixed (not user input);
  filenames come from `os.listdir` of our own dir, `text` is truncated.
