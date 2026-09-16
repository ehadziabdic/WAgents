# Provenance

- source: https://github.com/timwukp/MLOps-agent-skills
- upstream_head_at_vendoring: 6426013a15ee0e431dbb81938deac2f6e25c0941 (2026-07-31)
- vendored_at: 2026-09-16 (packs were copied in as `ml-mlops/` and `ml-llmops/` containers,
  then flattened into the flat skill registry)
- license: Apache-2.0 (upstream LICENSE)
- contents: 28 skills = 17 MLOps + 11 LLMOps
  - MLOps: ml-solution-design, data-ingestion, data-validation, feature-engineering,
    feature-store, ml-experiment-tracking, ml-pipeline-orchestration, model-training,
    model-registry, model-serving, model-monitoring, model-drift-detection,
    model-observability, ml-testing, ml-cicd, ml-security, ml-cost-optimization
  - LLMOps: llm-rag, llm-fine-tuning, llm-distillation, llm-evaluation, llm-data-preparation,
    llm-prompt-engineering, llm-agent-orchestration, llm-guardrails, llm-deployment,
    llm-observability, llm-cost-optimization
- notes: each skill is self-contained (ships its own `references/` and `scripts/`).
  Upstream directory prefixes (`skills/mlops/<name>`, `skills/llmops/<name>`) were dropped;
  skill directory names were kept unchanged.
- exclusive_to: ml-engineer
