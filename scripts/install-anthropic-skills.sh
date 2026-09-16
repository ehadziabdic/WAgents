#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "[wagents] anth-skills: verifying Anthropic-sourced skills..."

for s in anth-docx anth-pdf anth-pptx anth-xlsx anth-claude-api anth-webapp-testing anth-doc-coauthoring anth-mcp-builder; do
  test -f "$ROOT/.github/skills/$s/SKILL.md" || { echo "[wagents][fail] anthropic skill missing: $s" >&2; exit 1; }
  test -f "$ROOT/.github/skills/$s/LICENSE.txt" || echo "[wagents][warn] $s: upstream LICENSE.txt missing"
done

echo "[wagents] anth-skills: OK — 8 skills verified (docx, pdf, pptx, xlsx, claude-api, webapp-testing, doc-coauthoring, mcp-builder)"