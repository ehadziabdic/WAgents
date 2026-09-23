# PUBLIC RELEASE - strip audit trail

This tree IS the public edition, stripped from the private monorepo.
What was removed or redacted, verified by pattern sweep before push:

1. `local-share/auth.json` - provider API keys -> deleted.
2. `local-share/credentials.json` - all credential rows (opencode
   accounts, MCP OAuth, router keys) -> deleted.
3. `local-share/mcp-auth.json` - MCP OAuth tokens -> deleted.
4. `local-share/account.json` - account registry with keys -> deleted.
5. `rclone/rclone.conf` - Drive OAuth token -> deleted (README kept).
6. `opencode/service.json` - `"password"` set to `"CHANGE-ME"`.
7. `telegram/.telegram.env` - bot token + chat ID -> deleted
   (`.telegram.env.example` kept). `.voice-target-session` deleted.
8. `opencode/scripts/.jupyter.env` - Hub token -> deleted.
9. `opencode/opencode.json` - provider `apiKey` redacted.
10. `opencode/opencode.jsonc` - Figma Bearer redacted.
11. Machine state excluded throughout: `opencode.db` (165 MB, proven
    secret traces), logs, `.out/`, Brave profile, `__pycache__`,
    `node_modules`, `.wagents/` runtime, `commands/` dupe, `*.bak`.
12. Final sweep for token shapes (`ya29.`, `vck_`, `figu_`, `sk-ant-`
    + suffix, `AIza` + suffix, `1//0` + suffix, chat IDs): only
    documentation examples remain (vendored Anthropic docs show
    truncated key formats; the secret-pattern reference lists regexes).

Re-verify before any push with the same sweep; the command is in the
private repo's session history.
