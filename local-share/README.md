# local-share

Public edition: this folder ships placeholder JSON files only. No real
provider keys or OAuth tokens are in git.

At install time, replace the placeholders locally:

- `auth.json` - provider keys, via `opencode auth login` (repeat per
  account), or paste existing contents.
- `mcp-auth.json` - MCP OAuth tokens, created by client OAuth flows.
- `account.json` - opencode account registry, auto-created.
- `credentials.json` - credential rows for `import-credentials.ps1`;
  optional, public installs can skip it.
- `credentials-reference.json` - template for orphaned or legacy
  credentials; optional.

Keep real values out of git. The private edition keeps them for
multi-device sync; this public copy does not.
