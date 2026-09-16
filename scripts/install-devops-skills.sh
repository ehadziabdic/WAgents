#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "[wagents] devops-skills: verifying DevOps advisor skills..."

# 12 skills vendored from NotHarshhaa/devops-skills (MIT, pinned).
# Upstream `security-review` was intentionally NOT vendored (we ship awesome-security-review),
# and its shared contract docs are vendored as ../_devops-pack-docs/ (see its PROVENANCE.md).
for s in devops-audit devops-cost devops-db-review devops-docker-review devops-dr-review devops-incident devops-k8s-review devops-observability devops-pipeline-review devops-release-readiness devops-runbook devops-terraform-review; do
  test -f "$ROOT/.github/skills/$s/SKILL.md" || { echo "[wagents][fail] devops skill missing: $s" >&2; exit 1; }
done

# Shared contract/templates the skills link to as ../_devops-pack-docs/<file>
for d in skill-contract.md finding-format.md plan-template.md investigation-template.md skill-template.md PROVENANCE.md; do
  test -f "$ROOT/.github/skills/_devops-pack-docs/$d" || { echo "[wagents][fail] devops pack doc missing: $d" >&2; exit 1; }
done

echo "[wagents] devops-skills: OK — 12 skills + 5 shared contract docs verified"