#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "[wagents] ml-skills: verifying MLOps/LLMOps skills..."

# 28 skills vendored from timwukp/MLOps-agent-skills (Apache-2.0, pinned).
# 17 MLOps + 11 LLMOps. Each ships its own references/ and scripts/.
ML_SKILLS="ml-solution-design data-ingestion data-validation feature-engineering feature-store ml-experiment-tracking ml-pipeline-orchestration model-training model-registry model-serving model-monitoring model-drift-detection model-observability ml-testing ml-cicd ml-security ml-cost-optimization"
LLM_SKILLS="llm-rag llm-fine-tuning llm-evaluation llm-data-preparation llm-deployment llm-observability llm-cost-optimization llm-guardrails llm-prompt-engineering llm-agent-orchestration llm-distillation"

for s in $ML_SKILLS $LLM_SKILLS; do
  test -f "$ROOT/skills/$s/SKILL.md" || { echo "[wagents][fail] ml/llm skill missing: $s" >&2; exit 1; }
done

echo "[wagents] ml-skills: OK — 28 skills verified (17 MLOps + 11 LLMOps)"