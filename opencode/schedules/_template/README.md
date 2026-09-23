Each check lives in its own folder under `.config/opencode/schedules/<check_name>/`.

Folder layout:
- `watch.json`  - what to watch (logPath, donePattern, intervalMinutes, startedAt)
- `watch.log`   - append-only history of checks
- `run.ps1`     - optional per-check runner (defaults to scripts/check-training.ps1)

To add a new check (example: download_check):
1. Copy `_template/` to `download_check/`
2. Edit `download_check/watch.json`
3. Arm scheduler with that folder path

Template watch.json keys: logPath, donePattern, intervalMinutes, startedAt, notifyVia (telegram|chat).
