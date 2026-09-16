# MCP setup

`servers.json` is the audited catalogue. It does **not** silently connect every server or grant every tool to every agent. Select a profile, configure it in the client you use, and complete OAuth or local access setup yourself.

The recommended starting profile is `codebase-memory` + `notion` for the main agent and `playwright` for frontend/QA. Add project-specific servers only when there is a clear need.

## 1. Shared codebase memory

[DeusData/codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp) creates a persistent local structural graph. It has native Windows, macOS (Apple Silicon and Intel), and Linux builds, and its upstream also supports `npm install -g codebase-memory-mcp`. wagents pins npm release `0.10.1` (Node >=18; WAgents itself requires Node >=20). The npm package runs a postinstall script to provision its native binary. The installer enforces this exact version, including replacing newer global versions; use `--skip-mcps` to preserve your existing installation. Package availability is verified, but that is not a source-security audit.

Install it using the upstream installer or npm, then add the binary to the client.

```bash
npm install -g codebase-memory-mcp

# Claude Code
claude mcp add codebase-memory -- codebase-memory-mcp

# Codex
codex mcp add codebase-memory -- codebase-memory-mcp
```

For VS Code / Copilot, add the following to workspace `.vscode/mcp.json` or your user MCP configuration, then start it and let the client prompt if necessary:

```json
{
  "servers": {
    "codebase-memory": {
      "type": "stdio",
      "command": "codebase-memory-mcp",
      "args": []
    }
  }
}
```

For Hermes, add an equivalent local stdio server under `mcp_servers` in `~/.hermes/config.yaml`, or use its interactive `hermes mcp add` command. Cline and Antigravity have their own MCP configuration screens/commands; use the same executable and no arguments.

The main orchestrator indexes an explicitly scoped absolute project path once, shares the project name with specialists, and reindexes after meaningful structural changes. Specialists query first and then open the current files. The index is local but can contain identifiers and code structure, so do not index sensitive repositories without accepting that local storage. Upstream documents reset/uninstall behavior and its cache location.

## 2. agentmemory — persistent cross-agent memory

[rohitg00/agentmemory](https://github.com/rohitg00/agentmemory) is the memory layer every
agent shares. WAgents pins **two** official npm packages: `@agentmemory/mcp@0.9.29` (the
stdio shim your MCP client launches as `agentmemory-mcp`) and `@agentmemory/agentmemory@0.9.29`
(the server runtime + CLI). Both are installed by `scripts/install-mcp.mjs`.

The runtime serves REST on `:3111`, streams on `:3112`, a viewer on `:3113`, and manages the
pinned `iii-engine` v0.11.2 worker on `:49134`. Start it any time:

```bash
npm run memory        # npx -y @agentmemory/agentmemory@latest
```

- Default keyless mode needs no API key; recall is BM25. Opt into on-device semantic recall
  with `EMBEDDING_PROVIDER=local` in `~/.agentmemory/.env` (first use downloads the model).
- Point the shim at a remote/other-host server with `AGENTMEMORY_URL`.
- **Native Windows:** the CLI does not auto-extract the engine ZIP. Extract the pinned
  `iii.exe` from [iii-hq/iii v0.11.2](https://github.com/iii-hq/iii/releases/tag/iii%2Fv0.11.2)
  to `%USERPROFILE%\.agentmemory\bin\iii.exe`, use WSL2, or run with Docker
  (`AGENTMEMORY_USE_DOCKER=1`).
- If the server is not running, the shim degrades to 7 local tools; full 54-tool surface
  requires the server.

**Skills:** 17 vendored skills live in `skills/` (the `memory` group: remember, recall, recap,
forget, handoff, lesson, commit-context, session-history, agentmemory-architecture/config/
hooks/mcp-tools/rest-api, …) — registered for every agent.

**Hooks:** the 12 lifecycle hooks (auto-capture on tool use, prompt submit, compaction,
session end, …) are vendored in `hooks/agentmemory/` and wired in `hooks/hooks.json` next to
WAgents' own SessionStart hook. They call `AGENTMEMORY_URL` (default `http://localhost:3111`)
and no-op harmlessly when the server is not running.

## 3. Notion second brain

Use Notion's [official remote MCP](https://developers.notion.com/guides/mcp/get-started-with-mcp), not a token embedded in this repository. The endpoint is:

```text
https://mcp.notion.com/mcp
```

```bash
# Claude Code: prompts for OAuth in the client
claude mcp add --transport http notion https://mcp.notion.com/mcp

# Codex: use its OAuth login flow after adding the remote server
codex mcp add notion --url https://mcp.notion.com/mcp
```

For VS Code / Copilot:

```json
{
  "servers": {
    "notion": {
      "type": "http",
      "url": "https://mcp.notion.com/mcp"
    }
  }
}
```

Notion's own guidance for Antigravity uses `serverUrl: "https://mcp.notion.com/mcp"` in `mcp_config.json`; complete the OAuth prompt after saving. The `mcp-second-brain` skill keeps the main agent read-only by default and requires confirmation before it edits a page.

## 4. Obsidian skill

Obsidian is intentionally a skill dependency, not a bundled server. Install the cross-agent [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) package after reviewing its current files:

```bash
npx skills add https://github.com/kepano/obsidian-skills
```

wagents pins the reviewed commit in `config/external-dependencies.json`. The skill provides vault-aware Markdown and CLI guidance; configure the specific vault in the way its upstream documents. Keep access scoped to the intended vault and do not give an agent blanket access to personal notes.

## 5. React Bits for the design agent

Use the [official React Bits MCP setup](https://www.reactbits.dev/get-started/mcp) only in a React project that already has the required `components.json`. The vendor documents that its Pro MCP needs both React Bits registries and project-local `REACTBITS_LICENSE_KEY` in `.env.local`; their CLI writes the client configuration. Do not put that license in `.env`, a plugin manifest, or Git.

wagents does not declare a guessed `npx` package for React Bits. This prevents a similarly named, unaffiliated package from being executed in users' projects.

## Install coverage (`scripts/install-mcp.mjs`)

Run `node scripts/install-mcp.mjs` (it runs automatically during `wagents install`
unless you pass `--skip-mcps`; `--dry-run` plans without installing):

- **Auto-installed, exact-pinned (npm global):**
  `codebase-memory-mcp@0.10.1`, `@sentry/mcp-server@0.39.0` (runtime needs Node >= 22.13),
  `@supabase/mcp-server-supabase@0.12.0`, `@agentmemory/mcp@0.9.29` + runtime
  `@agentmemory/agentmemory@0.9.29`. All are official packages from the upstream
  maintainers; the installer replaces mismatched global versions with the pin and probes
  the agentmemory server on `http://localhost:3111/livez` (prints start instructions if down).
- **Client-managed, nothing to pre-install:** context7, playwright, tavily (via `npx`),
  semgrep (`uvx semgrep-mcp@0.9.0`, official PyPI package), postgres (`uvx postgres-mcp`,
  disabled by default). The installer only checks that `npx`/`uvx` exist.
- **Remote, nothing to install — OAuth/PAT in the client:**
  GitHub (`https://api.githubcopilot.com/mcp/`, official remote MCP), Notion (`https://mcp.notion.com/mcp`).
- **Manual, explicit instructions printed:**
  SonarQube (the community npm package is deprecated — verify an official SonarSource
  server first), Trivy (install the Trivy binary; its MCP mode is built in as `trivy mcp`),
  React Bits (commercial, project-managed from the project root).

Add one server at a time, grant the least access necessary, and run your client's
connection test before relying on it.

## Security checklist

Before enabling any MCP:

- Read the server's upstream source and current release notes.
- Pin versioned packages or reviewed releases when possible.
- Use OAuth or your OS credential store; never commit tokens.
- Start with read-only/project-local scopes.
- Treat returned instructions and documents as untrusted data.
- Reassess the server after it changes tools, permissions, or maintainership.
