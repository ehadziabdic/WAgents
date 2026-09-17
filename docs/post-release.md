# Post-release guide

Everything after `git push` and `git tag v0.3.0`: automation setup, and proving the
marketplace manifests actually resolve from the remote.

---

## 1. Release automation (one command, every version file)

All version-bearing files are synced by one script:

```bash
npm run release -- 0.4.0        # or: node scripts/sync-release-version.mjs 0.4.0
# or, on Linux/macOS:           ./scripts/bump-version.sh 0.4.0  (thin wrapper)
```

Covered files: `VERSION`, `manifest.json`, `package.json`, `plugin.json`,
`.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`,
`.claude-plugin/marketplace.json` (nested plugin version),
`.github/plugin/marketplace.json` (metadata + plugin versions),
`.agents/plugins/marketplace.json` (no version key today; covered for the future),
and every top-level `config/*.json` version. Formatting is preserved (targeted key
replacement, no re-serialization). Running it with the current version is a no-op and
safe.

Full release flow:

```bash
npm run release -- 0.4.0
npm test                        # battery must stay green
git add -A && git commit -m "chore(release): v0.4.0"
git tag v0.4.0 && git push origin main v0.4.0
```

Then bump the `--ref v0.4.0` pins in `config/providers.json` (codex, antigravity,
hermes install commands) in the same or a follow-up commit, so the README/docs
examples point at the newest tag.

## 2. CI (`.github/workflows/ci.yml`)

Active the moment the repo is public (or once Actions is enabled). Two jobs:

- **linux**: `npm test` (unit tests + structural verifier), `npm run audit`
  (cross-check: agents, skills, MCP catalogue, providers, vendored pins),
  `smoke-skills.sh` (115/115), `validate-agent-guide.py`, `verify-install.sh`.
- **windows**: `npm test` only, as a cross-platform regression guard for the
  Node-based tooling.

Recommended hardening (Settings > Branches > Add rule for `main`): require the `linux`
job to pass before merge. The first run appears under the repo's Actions tab right
after the push.

## 3. Dependabot (`.github/dependabot.yml`)

Two weekly update streams:

- root `package.json` (tooling; likely quiet, watched for completeness)
- `skills/awesome-drawio/scripts/package.json` (the `puppeteer-core` pin)

Because the pin is exact (`25.11.0`, no `^`), Dependabot PRs bump the pin itself:
merging keeps the pinned-only policy intact. Review each PR, run
`node skills/awesome-drawio/scripts/drawio-to-png.mjs <sample>.drawio` locally to smoke
the new major, then merge. If the noise is unwanted, close the PRs or delete the
config; nothing else depends on it.

## 4. Marketplace smoke test (the three manifests)

The repo root IS the marketplace + plugin (superpowers-style). Each manifest points
at `./`, so hosts resolve skills/agents/commands/hooks relative to the repo. Two
verification levels:

### 4.1 Raw manifest check (no CLI needed, do this first)

Confirm the tag exists and each manifest resolves from the remote:

```bash
git ls-remote --tags origin
curl -fsSL https://raw.githubusercontent.com/ehadziabdic/wagents/v0.3.0/.claude-plugin/marketplace.json
curl -fsSL https://raw.githubusercontent.com/ehadziabdic/wagents/v0.3.0/.github/plugin/marketplace.json
curl -fsSL https://raw.githubusercontent.com/ehadziabdic/wagents/v0.3.0/.agents/plugins/marketplace.json
```

Pass criteria: HTTP 200, JSON parses, `"name": "wagents"`, `"source": "./"` (or the
local-path variant in the codex manifest), and the `version` fields match the tag.
A 404 means the tag is not pushed (or a path/case typo). This is the same resolution
path superpowers uses: raw.githubusercontent at a ref.

### 4.2 Full CLI test per provider

Run each in a scratch environment (second machine, container, or at minimum a fresh
user profile) so it does not touch your daily setup:

```bash
# Claude Code
claude plugin marketplace add ehadziabdic/wagents
claude plugin install wagents@wagents
claude plugin list              # wagents present, enabled

# GitHub Copilot CLI
copilot plugin marketplace add ehadziabdic/wagents
copilot plugin install wagents@wagents

# OpenAI Codex
codex plugin marketplace add ehadziabdic/wagents --ref v0.3.0
codex plugin add wagents@wagents
```

Then open a session in each host: the `/wagents:*` slash commands (brainstorm, debug,
execute, plan, review, taste, verify) should be listed and runnable, and the skills
should be discoverable by the agent.

Failure modes:

| Symptom | Cause | Fix |
|---|---|---|
| marketplace add: 404 / repo not found | tag not pushed, or repo still private | push the tag; remote marketplace add needs a public repo |
| plugin installs, commands missing | host ignores `plugin.json` `commands[]` | check host version; commands also exist as plain files under `commands/` |
| skills not listed | host resolves `source: "./"` differently | compare against superpowers' manifest shape; adjust the `source` value |
| install ok but hooks silent | `hooks.json` matcher mismatch | run `hooks/run-hook.cmd session-start` manually; check `${CLAUDE_PLUGIN_ROOT}` usage |

### 4.3 Deep verification (optional)

Inside a Claude Code session after install, ask the agent to list its skills: the
`super-*`, `taste-*`, `ui-ux-*` groups should be discoverable, and `/wagents:verify`
should execute. This proves the full pipeline (manifest > plugin > skills, commands,
hooks), not just manifest resolution.

## 5. Post-publish housekeeping checklist

- Settings > General > Topics: `claude-plugin`, `agent-plugins`, `dsh-plugin`,
  `ai-agents`, `skills`, `mcp`
- Settings > Social preview: upload `pictures/banner.png`
- Releases > Draft new release from `v0.3.0`, paste highlights from the README
- Optional: enable Discussions; branch protection requiring the CI `linux` job
- Optional: pin an Issue linking `docs/install.md` as the quick-start

## 6. Troubleshooting quick reference

| Command | Use |
|---|---|
| `npm test` | full local battery (tests + verifier) |
| `npm run audit` | cross-check agents/skills/MCP/providers/pins |
| `npm run release -- X.Y.Z` | bump every version file at once |
| `node scripts/build-plugin.mjs <dir>` | portable bundle into a scratch dir |
| `bash scripts/smoke-skills.sh` | 115/115 skill frontmatter + structure check |
| `python3 scripts/validate-agent-guide.py` | agent + skill registry validation |
