# rclone (Google Drive remote `gdrive:`)

- `rclone.conf` - contains the Drive OAuth token. Private repo only.
- Install: `winget install Rclone.Rclone` (in install.ps1).
- Deploy: copy `rclone.conf` to `%APPDATA%\rclone\rclone.conf`.
- Uploads from the bot go to `gdrive:wagents-pc/`.
- Note: rclone warns its shared Drive client_id retires during 2026.
  If uploads start failing with auth errors, create your own client_id
  (https://rclone.org/drive/#making-your-own-client-id) and re-run
  `rclone config` for the gdrive remote.
