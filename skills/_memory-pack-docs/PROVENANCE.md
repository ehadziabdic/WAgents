# Provenance — agentmemory pack

- Source: https://github.com/rohitg00/agentmemory
- Pinned commit: `e04ba88819c365c9acf9d6661ea802143e728bd6` (main HEAD at vendored_at)
- Vendored at: 2026 (see pin above for the authoritative date)
- License: Apache-2.0 (upstream LICENSE copied here as `agentmemory-LICENSE`)
- What was vendored:
  - `plugin/skills/*` → `skills/` (17 skills + `_shared` support dir), verbatim, no renames (frontmatter `name` values are unique in this registry)
  - `plugin/scripts/*.mjs` (15 lifecycle hook scripts) → `hooks/agentmemory/`, wired in `hooks/hooks.json`
- Upstream bodies are never modified. To refresh: clone the new pin, re-copy `plugin/skills/*` and `plugin/scripts/*.mjs`, update the pin here and in `config/external-dependencies.json`.
- The skills are user-invocable memory operations (remember/recall/recap/forget/handoff/lesson/…) plus agentmemory-architecture/config/hooks/mcp-tools/rest-api references. The hooks auto-capture tool usage to the local agentmemory server (default `http://localhost:3111`, keyless, BM25).
- Related npm pins: `@agentmemory/mcp@0.9.29` (stdio MCP shim), `@agentmemory/agentmemory@0.9.29` (server runtime; manages iii-engine v0.11.2).
