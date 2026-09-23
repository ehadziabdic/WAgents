# inbox/

Watchers never message Telegram directly. They drop UTF-8 JSON files here and
the bot poll loop forwards them.

- `*.json` here get forwarded as `[auto] <text>` and then renamed to `*.sent`.
- `*.sent` are delivered (safe to delete or archive).
- Any other extension is ignored.

Emission contract: one JSON object, UTF-8, with a `text` key, max 4000 chars:

```json
{"text": "jupyter state changed: NO-SERVER-RUNNING -> SERVER-UP-NO-KERNELS:server1"}
```

Keep this folder (and this file). Empty dirs matter: the bot creates the dir
if missing, but the folder documents the contract.
