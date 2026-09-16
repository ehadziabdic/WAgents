# wagents

Portable, reproducible personal Agent OS for GitHub Copilot / Copilot CLI / VS Code.

Orchestrator + 11 specialists (incl. separate Hacker for authorized offensive work only).

Source of truth for agents, skills, instructions, MCP, manifests, verification, routing, security.

## Prerequisites

- `git`
- `gh` (optional, for repo/PR context)
- `node` LTS (for Context7, Playwright, most MCP servers)
- `python3` / `python` (for JSON verification)
- VS Code with Copilot + MCP support
- WSL or Git-Bash on Windows for `bash` scripts (native `install.ps1` also provided)

## One-command install (Linux/macOS)

```bash
git clone https://github.com/ehadziabdic/wagents.git
cd wagents
./install.sh
```

With authorized offensive skills (Hacker only):

```bash
CLAUDE_RED_REF=<pinned-sha> ./install.sh --include-hacker
```

## Windows install

```powershell
git clone https://github.com/ehadziabdic/wagents.git
cd wagents
.\install.ps1
.\install.ps1 -IncludeHacker
```

Windows Hacker note: vendor the pinned Claude-Red full copy via `CLAUDE_RED_REF=<pinned-sha> ./install.sh --include-hacker` (WSL/Git-Bash) or manual clone of `https://github.com/SnailSploit/Claude-Red` to `skills/base-hacker-claude-red/vendor/Claude-Red`, add `PROVENANCE.md`, preserve LICENSE. See `docs/skills.md`.

## Doctor / Update

Unix:

```bash
./scripts/doctor.sh
./scripts/update.sh
bin/wagents doctor
bin/wagents list
```

Windows:

```powershell
.\scripts\doctor.ps1
.\scripts\update.ps1
.\bin\wagents.ps1 doctor
```

`update` is pinned-only. No auto-upgrade. Safe to re-run `install`.

## Authentication setup

Copy `.env.example` to `.env` (never commit, gitignored):

```bash
cp .env.example .env
```

Set locally, via OS store, or CI secrets:

- `GITHUB_TOKEN` — GitHub MCP
- `TAVILY_API_KEY` — Tavily (researcher)
- `SENTRY_AUTH_TOKEN` — Sentry (read-only)
- `SONAR_TOKEN`, `SONAR_HOST_URL` — SonarQube (reviewer)
- `SEMGREP_APP_TOKEN` — optional, local rules work without
- `POSTGRES_CONNECTION_STRING` — conditional
- `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` — conditional
- `CLAUDE_RED_REF` — pinned sha for Hacker vendor

Configure VS Code MCP client from `mcp/servers.json`. See `docs/mcp.md`.

## Project initialization

Global is reusable. Project config overrides/extends global:

```bash
bin/wagents init
```

Then copy `templates/project/.github/*` into your project and customize:

```text
your-project/
├── .github/
│   ├── copilot-instructions.md
│   ├── agents/frontend-designer.agent.md
│   ├── skills/<project-skill>/SKILL.md
│   └── instructions/stack.instructions.md
```

See `templates/project/README.md` and `docs/architecture.md`.

## Agents

- `wagent` (default, main #1) — intent, architecture decisions, routing, parallel delegation, integration, validation
- `wagent-hacker` (main #2) — authorized offensive only, explicit target authorization, exclusive `base-hacker-claude-red`
- `frontend-designer` — UI/UX, accessibility, frontend implementation
- `backend-engineer` — APIs, auth, DB, business logic
- `security-engineer` — defensive security, threat modeling, scanning
- `code-reviewer` — independent review, read-only
- `debugger` — root-cause, minimal fix, regression test
- `qa-engineer` — unit/integration/E2E/browser
- `research-specialist` — web research, docs verification, comparisons
- `documentation-specialist` — docs, diagrams, slides, vaults, office-format deliverables
- `ml-engineer` — Python/data, ML, RAG/LLM, evaluation
- `devops-engineer` — Docker/CI/CD/cloud/deployment

Hacker (`wagent-hacker`) requires explicit target authorization. Only `wagent-hacker` uses the vendored claude-red set. Allowed: owned/local/lab/CTF/staging/explicitly authorized. See `docs/security.md`.

## Security model

- No secrets in git. Env only. `verify-install.sh` secret-scans.
- Least privilege per `config/permissions.json`. No wildcard full-access.
- `code-reviewer` and `research-specialist` are read/search only.
- Destructive/deployment/offensive actions require explicit authorization.
- Review MCP servers for prompt injection, tool poisoning, confused deputy, credential exposure. See `docs/security.md`.

## How to add new skills / MCPs

Skills:

1. Add `SKILL.md` under `skills/<group-prefix>-<name>/` (frontmatter `name:` must equal the directory name).
2. Add entry in `config/skills.json` (name, group, source, path, license, target_agents, status).
3. Scope in `config/permissions.json` if needed.
4. Add a group installer (`scripts/install-<group>-skills.sh`) if this is a new group, and wire it into `scripts/install-skills.sh` + `scripts/verify-install.sh` + `scripts/smoke-skills.sh`.
5. Run `scripts/verify-install.sh`, `scripts/smoke-skills.sh`, `python scripts/validate-agent-guide.py`.
6. Document in `docs/skills.md` if shared; record provenance (`PROVENANCE.md`, `LICENSE.txt`) and the pin in `config/external-dependencies.json` if third-party.

MCPs:

1. Add entry in `mcp/servers.json` (package, transport, required_env, scope).
2. Scope in `config/permissions.json`.
3. Document env in `.env.example` + `docs/mcp.md`.
4. Verify with `scripts/verify-install.sh` + `scripts/doctor.sh`.

## How to add / change agents

1. Add `agents/<id>.agent.md` with frontmatter `name`, `description`, `tools`.
2. Add entry in `config/agents.json` (id, file, role, delegates_to/exclusive_skills).
3. Scope tools/MCP in `config/permissions.json` + `mcp/servers.json` scopes.
4. Update `wagent.agent.md` routing if needed.
5. Run verification. Keep reviewer independent.

## Docs

- `docs/architecture.md` — hierarchy, orchestration, global vs project
- `docs/skills.md` — what to import, pins, provenance
- `docs/mcp.md` — tiers, scopes, env
- `docs/security.md` — privilege, hacker gate, MCP review
- `docs/troubleshooting.md` — doctor, common failures
- `docs/ui-references.md` — curated UI refs, ThreeUI unverified
- `mcp/README.md` — server source of truth
- `templates/project/` — override pattern
- `.github/hooks/README.md` — hook placeholders

## Known limitations

- Vendored pins live in `config/external-dependencies.json` (`ui-ux-pro-max`, `taste-skill`, `obsidian-skills`, `claude-red`, `anthropic-skills`, `devops-skills`, `mlops-agent-skills`, `superpowers`) with `PROVENANCE.md` next to each set. Refresh via the matching `scripts/install-*-skills.sh` (see `docs/skills.md`).
- The claude-red vendor (`base-hacker-claude-red`, 78 skills) is local-working-copy only: it ships committed in this setup, but `scripts/build-plugin.mjs` strips it from the portable core plugin. Re-vendor with `bash scripts/install-base-skills.sh --include-hacker`.
- The `anth-*` office/document skills declare a **Proprietary** license. Review those terms before publishing them inside a public package or plugin (see `docs/skills.md` and each skill's license file).
- MCP client wiring is per-client (VS Code settings from `mcp/servers.json`), not auto-linked globally.
- `ThreeUI` reference in handoff §13 unverified — do not invent URL, verify before documenting.
- No overengineered CLI yet — `bin/wagents` (+ `.ps1`) is thin wrapper over scripts, per handoff §9.

## License

MIT. Third-party skills preserve upstream attribution.


