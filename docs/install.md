# Installing wagents — all platforms, all providers

**Requirements (every OS):** `git`, `node` >= 20 (wagents CLI + npm MCPs), `bash` on
Windows via Git Bash or WSL for the `.sh` helpers (PowerShell entry points are provided),
`python` 3 for `scripts/validate-agent-guide.py` (verification only).

Two provider CLIs have stricter runtimes of their own: Sentry's MCP runtime wants
Node >= 22.13, and DeepSeek Harness (`dsh`) wants Node ^22.19 || >= 24. Both are checked
and reported, never silently assumed.

## Platform matrix

| Capability | Linux | macOS | Windows |
|---|---|---|---|
| `wagents` CLI (`bin/wagents.mjs`, pure Node) | yes | yes | yes (spawns provider CLIs through cmd.exe so npm `.cmd` shims resolve) |
| One-command install script | `./install.sh` | `./install.sh` | `.\install.ps1` |
| Doctor / update | `scripts/doctor.sh`, `scripts/update.sh` | same | `scripts/doctor.ps1`, `scripts/update.ps1` |
| npm MCP auto-install (`scripts/install-mcp.mjs`) | yes | yes | yes (npm spawned with `shell: true`; `.cmd` shims safe) |
| agentmemory server | yes (`npm run memory`) | yes | yes via WSL2 / Docker (`AGENTMEMORY_USE_DOCKER=1`) or the pinned `iii.exe` in `%USERPROFILE%\.agentmemory\bin` (see `mcp/README.md`) |
| Hooks | `hooks/session-start.sh` | same | `hooks/run-hook.cmd` + `hooks/session-start.ps1`; agentmemory hook scripts are portable `.mjs` |

## Route 1 — plugin marketplace (Claude Code, Copilot CLI, Codex)

The repo root **is** the plugin and ships its own marketplace manifests
(`.claude-plugin/marketplace.json`, `.github/plugin/marketplace.json`,
`.agents/plugins/marketplace.json`), all pointing at `./`. After cloning (or installing
from GitHub — see Route 2), point your CLI at the checkout:

```bash
# Claude Code
claude plugin marketplace add /path/to/wagents
claude plugin install wagents@wagents

# GitHub Copilot CLI
copilot plugin marketplace add /path/to/wagents
copilot plugin install wagents@wagents

# OpenAI Codex
codex plugin marketplace add /path/to/wagents
codex plugin add wagents@wagents

# Google Antigravity
agy plugin install /path/to/wagents

# Hermes Agent
hermes plugins install /path/to/wagents --enable
```

Or, once the repo is on GitHub, install straight from the remote:

```bash
claude plugin marketplace add ehadziabdic/wagents
copilot plugin marketplace add ehadziabdic/wagents
codex plugin marketplace add ehadziabdic/wagents --ref <release-commit>
```

The all-in-one equivalent for any provider is:

```bash
wagents install --provider <name>   # --dry-run to preview; --skip-mcps to defer MCP installs
```

## Route 2 — npm (global CLI + tarball installs)

```bash
npm install -g github:ehadziabdic/wagents#<release-tag>   # or: git clone && npm install -g .
wagents doctor                                            # structural verification
wagents install --provider copilot                        # pick your provider
```

The npm `files` manifest ships `bin/`, `skills/`, `agents/`, `instructions/`, `commands/`,
`hooks/` (including `hooks/agentmemory/`), `config/`, `mcp/`, and the marketplace manifests,
so a global npm install is a complete plugin. `prepack` runs `build:plugin` + `verify`
before any tarball is produced.

## Route 3 — provider-native setup (DeepSeek Harness, Cline)

- **DeepSeek Harness (`dsh`)** — npx-first developer preview, no marketplace subcommand yet:
  1. `npx -y @deepseek-ai/dsh web` (Web UI on `http://127.0.0.1:3080`; dsh needs Node ^22.19 || >=24)
  2. `npm install github:ehadziabdic/wagents` in the dsh workspace
  3. Register the plugin in `cordis.yml`:
     ```yaml
     plugins:
       wagents:
     ```
  4. MCP servers go in `$DSH_HOME/cordis.patch.yml` (home-level patch layer every profile
     loads); agentmemory tools surface as `mcp__agentmemory__*` — see
     `skills/agentmemory-agents/REFERENCE.md`.
  5. `wagents install --provider deepseek-harness` prints these steps at any time.
     dsh ships breaking changes — pin the version you test with.

- **Cline** — Agent Skills adapter: `wagents install --provider cline` copies the full
  skill set to `.cline/skills/` in the current project (never overwrites existing files).

## Provider status summary (`wagents list providers`)

| Provider | Status | Install via |
|---|---|---|
| claude-code | supported | marketplace (`claude plugin …`) |
| codex | supported | marketplace (`.agents/plugins/marketplace.json`) |
| copilot | supported | marketplace (`.github/plugin/marketplace.json`) |
| antigravity | supported | `agy plugin install` |
| cline | supported-with-skill-adapter | skills copy to `.cline/skills/` |
| hermes | supported | `hermes plugins install` |
| deepseek-harness | supported-preview | npx + `cordis.yml` registration |

## Maintainer: publishing the marketplace (one-time)

1. Push this repo to GitHub (`origin` → `github.com/ehadziabdic/wagents`). GitHub slugs are
   case-insensitive, so `WAgents` and `wagents` resolve identically.
2. Tag the release so `<release-commit>` refs are meaningful:
   `git tag v0.3.0 && git push origin v0.3.0` (or run `scripts/bump-version.sh` first).
3. That's it for the manifests — all three already point at the repo root. Users then run
   the `marketplace add ehadziabdic/wagents` commands above; no separate marketplace repo
   is needed (superpowers-style: repository root = marketplace + plugin).
4. Optional discoverability topics on the GitHub repo: `claude-plugin`, `agent-plugins`,
   `dsh-plugin` (DeepSeek's plugin index tracks the `dsh-plugin` topic).
5. Verify from a second machine or a clean clone: `claude plugin marketplace add
   ehadziabdic/wagents && claude plugin install wagents@wagents`, then `wagents doctor`.

## After installing

1. `cp .env.example .env` and set the tokens you use (never commit it).
2. `wagents install --provider <name>` (auto-installs the pinned npm MCPs; `--skip-mcps` defers).
3. Start the memory server: `npm run memory` (`http://localhost:3111`; hooks no-op when it's down).
4. `wagents doctor` / `wagents list providers` to confirm.

