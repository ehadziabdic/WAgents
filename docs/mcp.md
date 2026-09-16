# MCP — wagents

Source of truth: `mcp/servers.json`. Scopes: `config/permissions.json`.
Install strategies (`install` key per server): `npm-pinned` (auto-installed at an exact
version by `scripts/install-mcp.mjs`), `client-managed` (client launches npx/uvx on
demand), `remote` (HTTP + OAuth in the client), `manual` (explicit setup required).

## Tiers (matches `mcp/servers.json`)

Tier 1 (shared):
- agentmemory `agentmemory-mcp` — persistent cross-agent memory for every agent
  (auto-installed, pinned `@agentmemory/mcp@0.9.29` shim + `@agentmemory/agentmemory@0.9.29`
  runtime; server on REST :3111 / viewer :3113, keyless BM25 by default,
  `EMBEDDING_PROVIDER=local` opt-in; ships 17 vendored skills in the `memory` group
  and 12 auto-capture lifecycle hooks in `hooks/agentmemory/` — see `mcp/README.md`)
- Context7 `@upstash/context7-mcp` — current docs, no secret (client-managed via npx)
- GitHub official remote MCP `https://api.githubcopilot.com/mcp/` — OAuth/PAT in the
  client, nothing to install (local `github-mcp-server` binary is a manual alternative)
- Playwright `@playwright/mcp` — browser testing, no secret (client-managed via npx)
- codebase-memory `codebase-memory-mcp` — persistent local structural index, no secret
  (auto-installed, pinned npm release `0.10.1`, upstream `DeusData/codebase-memory-mcp`;
  orchestrator owns indexing, specialists query first — see `mcp/README.md` and
  `mcp-codebase-memory`)
- Notion official remote MCP `https://mcp.notion.com/mcp` — OAuth in the client
  (main-agent read by default, writes need confirmation — see `mcp-second-brain`)

Tier 2:
- Tavily `tavily-mcp` — needs `TAVILY_API_KEY`, researcher/architect-read (client-managed via npx)
- Sentry `@sentry/mcp-server` — auto-installed pinned `0.39.0` (official getsentry
  package; needs `SENTRY_AUTH_TOKEN` at runtime; requires Node >= 22.13)
- SonarQube — manual: the community npm package is deprecated; verify an official
  SonarSource server before adopting (needs `SONAR_TOKEN` + `SONAR_HOST_URL`)
- Trivy `trivy mcp` — built-in MCP mode; install the Trivy binary first (manual)
- Semgrep — official PyPI `semgrep-mcp` pinned `0.9.0`, launched on demand via
  `uvx` (local rules work without `SEMGREP_APP_TOKEN`)
- React Bits — project-managed commercial MCP for the design agent only
  (requires the project's own `components.json` + `REACTBITS_LICENSE_KEY` in project
  `.env.local`; wagents declares no guessed package — see `mcp/README.md`)

Conditional (disabled by default):
- Postgres `postgres-mcp` — launched on demand via `uvx` only when explicitly enabled,
  needs `POSTGRES_CONNECTION_STRING`, backend only
- Supabase `@supabase/mcp-server-supabase` — auto-installed pinned `0.12.0` (official;
  needs `SUPABASE_ACCESS_TOKEN`, backend only)
- Additional cloud MCPs — only when explicitly needed per project

## Least privilege

Do not expose every server to every agent. See `config/permissions.json` for per-agent `mcp` allow-list and `forbidden` list.

Examples (scopes live in `mcp/servers.json`, enforced in `config/permissions.json`):
- main agents (`wagent`, `wagent-hacker`): codebase-memory (index + query), agentmemory (save/recall, all agents), notion read-default, context7
- frontend-designer: context7, playwright, codebase-memory query, react-bits (project-managed)
- researcher: tavily, context7, github-read
- security-engineer: context7, github-read, semgrep, trivy, sonarqube-read, sentry-read
- code-reviewer: github-read, context7, sonarqube-read (read/search only, no edit)
- wagent-hacker: context7, github-read, semgrep, trivy + exclusive `base-hacker-claude-red` skills, explicit target authorization

## Setup

1. Copy `.env.example` to `.env` (never commit).
2. Set required tokens locally.
3. Configure the MCP client you use from `mcp/servers.json` (VS Code workspace
   `.vscode/mcp.json`, Claude Code / Codex `mcp add`, Hermes `mcp_servers`, …).
4. Run `scripts/verify-install.sh` and `scripts/doctor.sh`.
5. Install the two skill-side walkthroughs alongside the servers:
   `mcp-codebase-memory` (index/query routine), `mcp-shared-codebase-memory`
   (multi-agent sharing), `mcp-second-brain` (Notion/Obsidian read rules).

See `mcp/README.md` (per-server setup) and `docs/security.md` (secret handling + server review checklist).
