---
name: mcp-shared-codebase-memory
description: Build and use a shared structural map of the current codebase through codebase-memory-mcp. Use before multi-agent work, architecture exploration, or a repeated codebase question when the MCP is installed.
license: MIT
---

# Shared Codebase Memory

`codebase-memory-mcp` stores a local, persistent structural index. It reduces repeated exploration; it is not an authority over the files on disk.

## Orchestrator workflow

1. Check whether the MCP is installed and the current repository is already indexed.
2. Index or refresh the repository only when appropriate for the user's scope. Use an absolute project path and never index directories the user did not place in scope.
3. Share the project name and the relevant graph findings with delegated agents.
4. Re-index after a meaningful structural change if later agents need the new shape.

## Specialist workflow

1. Query the graph first for symbols, call paths, dependency boundaries, or likely owners.
2. Open the current files before making a conclusion or edit—indexes can be stale.
3. Identify graph results as supporting evidence, not proof.

## Safety and privacy

- The local index may contain source-code structure and identifiers. Do not index repositories containing secrets unless the user has explicitly accepted that local storage.
- Do not expose indexes, paths, or query results outside the user's approved workspace.
- See `mcp/README.md` for installation, persistence location, and uninstall/reset instructions.
