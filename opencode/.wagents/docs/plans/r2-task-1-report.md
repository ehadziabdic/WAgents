# R2 Task 1 Report: /zip and /unzip

Status: DONE

Files changed:
- C:\Users\eminha\.config\opencode\scripts\telegram-pc-bot.py
  - Added `shutil` to top-level imports.
  - Added `RCLONE_EXE` constant (shutil.which("rclone") or winget path).
  - Added /zip block exactly per plan (tempfile zip, dir via make_archive, single file via ZipFile, >45MB falls back to gdrive:wagents-pc/ link).
  - Added /unzip block exactly per plan (extract next to archive, reply with listing).
  - Added /help lines for /zip and /unzip.

Tests:
- `python -m py_compile telegram-pc-bot.py` -> EXIT:0
- No bot restart performed (controller owns restart).

Notes:
- /drive block left with its existing inline rclone fallback (functionally identical to RCLONE_EXE); /zip uses `shutil.which("rclone") or RCLONE_EXE` per plan.
- Allowlist + home-jail (jail()) enforced on both new commands. No secrets added.
