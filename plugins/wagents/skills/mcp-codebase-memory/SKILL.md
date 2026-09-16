---
name: mcp-codebase-memory
description: Local-first codebase knowledge graph powered by tree-sitter (158+ languages) and codebase-memory-mcp. Use to index, search, and navigate code topology, symbol dependencies, and call graphs without wasting context tokens.
license: MIT
---

# Codebase Memory (AST Knowledge Graph)

Use this skill to navigate, query, and reason about codebase architecture using persistent AST indexing powered by [`DeusData/codebase-memory-mcp`](https://github.com/DeusData/codebase-memory-mcp).

## Core Principles

1. **Graph Before File Dump**: Never read entire directories or large code trees with brute-force grep when the knowledge graph is available. Query the AST graph to find exact symbols, references, and callers.
2. **Local & Private**: Indexes are stored locally on your machine. No source code or tokens leave your local environment.
3. **Evidence Verification**: The AST graph provides rapid structural mapping; always inspect the current source file at the identified line numbers before concluding an edit.

## Orchestrator Workflow

1. **Initialization & Indexing**:
   - Verify if `codebase-memory` MCP is available in the current session.
   - Run indexing on the workspace root:
     ```text
     mcp__codebase-memory__index_repository(path: "<workspace-root>")
     ```
   - Confirm indexing status and share graph context with specialist subagents.
2. **Re-Indexing**:
   - Trigger incremental re-indexing after significant refactors or major dependency upgrades.

## Specialist Agent Workflow

### 1. Symbol & Definition Discovery (`architect`, `backend-engineer`, `frontend-designer`)
- Find where symbols, types, interfaces, or functions are declared:
  ```text
  mcp__codebase-memory__find_definition(symbol: "UserService")
  ```
- Map imports and exported boundaries across modules.

### 2. Dependency & Call Hierarchy (`debugger`, `code-reviewer`, `security-engineer`)
- Trace who calls a sensitive function or where errors might propagate:
  ```text
  mcp__codebase-memory__find_callers(function: "processPayment")
  mcp__codebase-memory__find_references(symbol: "DATABASE_URL")
  ```
- Inspect inheritance chains, interface implementations, and overrides.

### 3. Architecture Exploration
- Map all classes, structs, or functions matching a domain or regex pattern.
- Identify dead code, orphan modules, and tightly-coupled circular imports.

## Best Practices

- **Token Economy**: Using AST queries reduces prompt token consumption by up to 99% compared to full-directory scans.
- **Verification Gate**: Indexes may occasionally lag behind uncommitted live buffer edits. Check file modification timestamps if a query fails to match live code.
