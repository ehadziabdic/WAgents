# local-share

Public edition: this folder ships EMPTY on purpose (no secrets in git).

At install time the agent creates here:
- `auth.json` - provider keys, via `opencode auth login` (repeat per
  account), or paste existing contents.
- `mcp-auth.json` - MCP OAuth tokens, created by client OAuth flows.
- `account.json` - opencode account registry, auto-created.
- `credentials.json` - NOT used in public edition (private backfill
  tool only; see import-credentials.ps1 in the private repo).
