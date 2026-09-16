#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "[wagents] super-skills: verifying super skills..."

for s in super-brainstorming super-dispatching-parallel-agents super-executing-plans super-finishing-a-development-branch super-receiving-code-review super-requesting-code-review super-subagent-driven-development super-systematic-debugging super-test-driven-development super-using-git-worktrees super-using-superpowers super-verification-before-completion super-writing-plans super-writing-skills; do
  test -f "$ROOT/skills/$s/SKILL.md" || { echo "[wagents][fail] super skill missing: $s" >&2; exit 1; }
done

echo "[wagents] super-skills: OK — 14 skills verified"