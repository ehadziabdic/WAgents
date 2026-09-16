# MCP — wagents

Source of truth: `mcp/servers.json`. Scopes: `config/permissions.json`.

## Tiers (matches `mcp/servers.json`)

Tier 1 (shared):
- Context7 `@upstash/context7-mcp` — current docs, no secret
- GitHub `github-mcp-server` — needs `GITHUB_TOKEN`
- Playwright `@playwright/mcp` — browser testing, no secret
- codebase-memory `codebase-memory-mcp` — persistent local structural index, no secret
  (pinned npm release `v0.10.1`, upstream `DeusData/codebase-memory-mcp`; orchestrator owns
  indexing, specialists query first — see `mcp/README.md` and `mcp-codebase-memory`)
- Notion official remote MCP `https://mcp.notion.com/mcp` — OAuth in the client
  (main-agent read by default, writes need confirmation — see `mcp-second-brain`)

Tier 2:
- Tavily `tavily-mcp` — needs `TAVILY_API_KEY`, researcher/architect-read
- Sentry `sentry-mcp` — needs `SENTRY_AUTH_TOKEN`, read-only
- SonarQube `sonarqube-mcp` — needs `SONAR_TOKEN` + `SONAR_HOST_URL`, reviewer
- Trivy `trivy-mcp` — filesystem/container/deps, no secret
- Semgrep `semgrep-mcp` — needs `SEMGREP_APP_TOKEN` optional, local rules work without
- React Bits — project-managed commercial MCP for the design agent only
  (requires the project's own `components.json` + `REACTBITS_LICENSE_KEY` in project
  `.env.local`; wagents declares no guessed package — see `mcp/README.md`)

Conditional (disabled by default):
- Postgres `postgres-mcp` — needs `POSTGRES_CONNECTION_STRING`, backend only
- Supabase `supabase-mcp` — needs `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY`, backend only
- Additional cloud MCPs — only when explicitly needed per project

## Least privilege

Do not expose every server to every agent. See `config/permissions.json` for per-agent `mcp` allow-list and `forbidden` list.

Examples (scopes live in `mcp/servers.json`, enforced in `config/permissions.json`):
- main agents (`wagent`, `wagent-hacker`): codebase-memory (index + query), notion read-default, context7
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
