# Troubleshooting — wagents

## Verify first

```bash
./scripts/verify-install.sh
./scripts/doctor.sh
```

Windows:

```powershell
.\install.ps1
```

`doctor` checks: 12 agents, 98 skills, manifests, JSON validity, secret-scan, git/gh/node/python3, hacker vendor status.

## Common issues

### `python3 not found`
- Verify needs `python3` for JSON validation.
- Windows: `install.ps1` uses `python` fallback. Install Python 3 and retry.
- Unix: `apt install python3` / `brew install python3`.

### `missing skill <name>`

- Checked skills must exist under `skills/<name>/SKILL.md` (frontmatter `name:`
  must equal the directory name).
- Run `bash scripts/install-skills.sh` to check all per-group sets, `bash scripts/smoke-skills.sh`
  for the full registry, `python scripts/validate-agent-guide.py` for agent references.
- Do not rename directories without updating `config/skills.json` and the owning agent file.

### `hacker vendor not installed`

- Expected unless `--include-hacker` used.
- Unix: `CLAUDE_RED_REF=<sha> ./install.sh --include-hacker`
- Windows: WSL/Git-Bash with the same command, or manual clone of
  `https://github.com/SnailSploit/Claude-Red` to `skills/base-hacker-claude-red/vendor/Claude-Red`,
  plus `PROVENANCE.md`, preserve LICENSE.
- Current pin lives in `config/external-dependencies.json` (`claude-red.pinned_commit`) and
  `scripts/install-base-skills.sh`. See `docs/skills.md` → "Updating a vendored set".

### `servers.json invalid`
- Validate: `python3 -c "import json; json.load(open('mcp/servers.json'))"`
- Check trailing commas, comments (JSON does not allow comments).
- Compare against `mcp/README.md` tiers.

### `secret-scan` fails
- `verify-install.sh` greps for `sk-ant-`, `ghp_`, `github_pat_`, `AKIA`.
- Remove secrets from tracked files. Use `.env` (ignored) or OS store.
- Check `.github/`, `config/`, `mcp/`, `scripts/`.

### MCP auth errors
- Required env (local only, never in git): `GITHUB_TOKEN`, `TAVILY_API_KEY`, `SENTRY_AUTH_TOKEN`, `SONAR_TOKEN`, `SONAR_HOST_URL`.
- Copy `.env.example` to `.env`. Do not commit `.env`.
- VS Code MCP client must load from `mcp/servers.json`. See `docs/mcp.md`.

### `gh not found`
- Optional. Install GitHub CLI for repo/PR context.
- Without `gh`, GitHub MCP still works if `GITHUB_TOKEN` set.

### `node not found`
- Needed for Context7, Playwright, and most MCP servers.
- Install Node LTS. Retry `doctor`.

### Installer not idempotent
- `install.sh` / `install.ps1` are safe to re-run.
- They check, never overwrite local `.env`.
- If custom edits lost, check `git diff` — `update.sh` is pinned-only, never destroys local customization.

### Project override not working
- Global is reusable. Project config overrides/extends global.
- See `templates/project/` for pattern.
- Ensure project file paths take precedence in your Copilot/VS Code setup.

## Getting help

1. Run `doctor`, capture output.
2. Check `docs/architecture.md`, `docs/skills.md`, `docs/mcp.md`, `docs/security.md`.
3. Inspect `config/*.json` for pins and scopes.
4. File issue with doctor output (redact tokens).
