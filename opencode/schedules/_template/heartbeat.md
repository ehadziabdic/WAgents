# Heartbeat: how any watcher emits alerts

Watchers never message Telegram directly. The bot poll loop drains
`schedules/inbox/*.json` each iteration and forwards each as `[auto] <text>`.

## Emit from any watcher (PowerShell)

```powershell
$InboxDir = Join-Path (Split-Path -Parent $CheckDir) "inbox"
if (-not (Test-Path $InboxDir)) { New-Item -ItemType Directory $InboxDir | Out-Null }
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$text = "mycheck: one-line human summary here"
if ($text.Length -gt 4000) { $text = $text.Substring(0, 4000) }
$payload = @{ text = $text } | ConvertTo-Json -Compress
$outFile = Join-Path $InboxDir ("mycheck-" + $ts + ".json")
[System.IO.File]::WriteAllText($outFile, $payload, [System.Text.UTF8Encoding]::new($false))
```

Filename pattern: `<check>-<yyyyMMdd-HHmmss>.json` (add `-<pid>` suffix if two
emits can land in the same second).

## Emit from Python

```python
import json, os, datetime
box = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "schedules", "inbox"))
os.makedirs(box, exist_ok=True)
ts = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
text = "mycheck: one-line human summary here"[:4000]
fp = os.path.join(box, f"mycheck-{ts}.json")
open(fp, "w", encoding="utf-8").write(json.dumps({"text": text}))
```

## Rules

1. Emission contract: UTF-8 JSON object with a `text` key, max 4000 chars.
   The bot truncates to 4000 and prefixes `[auto] `.
2. State-change only: keep a `last-state.txt` next to your check script,
   compare the full status output each run, and emit only when it differs.
   Healthy steady-state stays silent. First run writes the baseline and
   stays silent (no previous state to diff against).
3. Keep stdout human-readable: the bot `/status` path may call your check
   script directly, so always print the current state to stdout even when
   you do not emit (silent runs still log normally).
4. One file per event: the bot renames each delivered file to `*.sent`.
   Never write `*.sent` yourself; never reuse a filename.
5. No secrets in `text` or filenames. Tokens stay in untracked `.env` files.
