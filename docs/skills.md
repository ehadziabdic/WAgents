# Skills — wagents

**Source of truth:** `config/skills.json` (registry + `target_agents`) and `skills/*/SKILL.md`.
**Total: 115 skills** in 11 groups, plus 3 underscore-prefixed support directories.

Verified by:

```bash
bash scripts/verify-install.sh        # structural checks (agents, skills, configs, secrets)
bash scripts/install-skills.sh        # per-group installers
bash scripts/smoke-skills.sh          # all 115 skills: SKILL.md + frontmatter present
python scripts/validate-agent-guide.py  # agent/skill frontmatter + references
```

## Groups

| Group | Count | Prefix | Contents |
|---|---|---|---|
| `anth` | 8 | `anth-` | Anthropic-sourced skills: office formats (docx/pdf/pptx/xlsx), Claude API, web app testing, doc co-authoring, MCP builder |
| `awesome` | 4 | `awesome-` | documentation writer (Diátaxis), draw.io diagrams, Microsoft docs, security review |
| `base` | 4 | `base-` | architecture blueprint, design references, webapp testing basics, claude-red vendor (hacker-exclusive) |
| `devops` | 12 | `devops-` | read-only DevOps advisors: audit, incident, runbook, k8s/terraform/docker/db review, pipeline, release readiness, observability, cost, DR |
| `memory` | 17 | `agentmemory-`, `remember`, `recall`, `recap`, `forget`, `handoff`, `lesson`, `commit-context`, `commit-history`, `session-history`, `memory-discipline`, `write-agentmemory-skill` | persistent cross-agent memory operations (vendored from rohitg00/agentmemory at a pinned commit; requires the agentmemory MCP — every agent may use it) |
| `mcp` | 3 | `mcp-` | codebase memory, shared codebase memory, second brain |
| `ml` | 28 | `ml-`, `llm-`, `model-`, `data-`, `feature-` | 17 MLOps + 11 LLMOps lifecycle skills |
| `obsidian` | 6 | `obsidian-` | vault authoring: markdown, bases, canvas, defuddle, knap, CLI |
| `super` | 14 | `super-` | engineering workflow methodology (brainstorm, plan, execute, verify, review, worktrees, TDD, debugging) |
| `taste` | 12 | `taste-` | anti-slop design, redesign, image-directed frontend |
| `ui-ux` | 7 | `ui-ux-` | design intelligence, design systems, brand, banners, slides, styling |

## Agent → skill mapping (authoritative: `config/skills.json`)

Every agent (all 12, mains and specialists alike) may use the `memory` group skills —
they operate on the shared agentmemory MCP server, so anything one agent remembers is
recallable by another.

| Agent | Skills |
|---|---|
| **wagent** (main) | super-using-superpowers, super-brainstorming, super-writing-plans, super-executing-plans, super-dispatching-parallel-agents, super-subagent-driven-development, super-using-git-worktrees, super-requesting-code-review, super-receiving-code-review, super-verification-before-completion, super-finishing-a-development-branch, super-writing-skills, base-architecture-blueprint, awesome-drawio, awesome-microsoft-docs, awesome-documentation-writer, mcp-codebase-memory, mcp-shared-codebase-memory, mcp-second-brain |
| **wagent-hacker** (main) | base-hacker-claude-red (exclusive), super-writing-plans, super-executing-plans, super-dispatching-parallel-agents, super-verification-before-completion, mcp-codebase-memory |
| frontend-designer | ui-ux-pro-max, ui-ux-design, ui-ux-design-system, ui-ux-ui-styling, ui-ux-brand, ui-ux-banner-design, ui-ux-slides, taste-skill, taste-gpt-tasteskill, taste-soft-skill, taste-minimalist-skill, taste-brutalist-skill, taste-redesign-skill, taste-stitch-skill, taste-image-to-code-skill, taste-imagegen-frontend-web, taste-imagegen-frontend-mobile, taste-brandkit, taste-output-skill, base-design-references, base-webapp-testing-basics, mcp-codebase-memory |
| backend-engineer | super-test-driven-development, anth-claude-api, anth-mcp-builder, awesome-microsoft-docs, taste-output-skill, mcp-codebase-memory |
| security-engineer | awesome-security-review, awesome-microsoft-docs, mcp-codebase-memory |
| code-reviewer | super-requesting-code-review, super-receiving-code-review, super-verification-before-completion, awesome-security-review, mcp-codebase-memory |
| debugger | super-systematic-debugging, base-webapp-testing-basics, mcp-codebase-memory |
| qa-engineer | base-webapp-testing-basics, super-test-driven-development, anth-webapp-testing, mcp-codebase-memory |
| research-specialist | awesome-microsoft-docs, awesome-documentation-writer, mcp-second-brain, mcp-codebase-memory |
| documentation-specialist | awesome-documentation-writer, awesome-microsoft-docs, awesome-drawio, ui-ux-slides, taste-output-skill, anth-docx, anth-pdf, anth-pptx, anth-xlsx, anth-doc-coauthoring, obsidian-markdown, obsidian-bases, obsidian-json-canvas, obsidian-defuddle, obsidian-knap, obsidian-cli, mcp-codebase-memory, mcp-second-brain |
| ml-engineer | 17 MLOps + 11 LLMOps skills, anth-claude-api, super-test-driven-development, awesome-microsoft-docs, mcp-codebase-memory |
| devops-engineer | 12 devops-* skills, awesome-drawio, awesome-microsoft-docs, taste-output-skill, mcp-codebase-memory |

**Universal:** every agent may use `mcp-codebase-memory` (query-first navigation before any brute-force scan).

## Vendored / pinned third-party sets

Every vendored set keeps upstream license text, a pinned ref, and a `PROVENANCE.md`.

| Set | Source | Pin | Location |
|---|---|---|---|
| claude-red (78 offensive skills, 22 categories) | `SnailSploit/Claude-Red` (MIT) | `24d7968bab4b883e7f13477afe0fd91f2df3b722` | `skills/base-hacker-claude-red/vendor/Claude-Red/` + `vendor/PROVENANCE.md` |
| office + utility skills | `anthropics/skills` | `34040c9c568585f6929bedeaad110ad08f079624` | `skills/anth-*/` (+ `PROVENANCE.md` per skill, `LICENSE.txt` preserved) |
| devops advisors (12) | `NotHarshhaa/devops-skills` (MIT) | `b3d56768774d11656c47bd7abbd81fbf2bd630e5` | `skills/devops-*/` |
| devops shared contract docs | same | same | `skills/_devops-pack-docs/` (+ `PROVENANCE.md`) |
| MLOps + LLMOps (28) | `timwukp/MLOps-agent-skills` (Apache-2.0) | upstream HEAD `6426013a15ee0e431dbb81938deac2f6e25c0941` at vendoring | `skills/<ml,llm,model,data,feature>-*/` |
| ML pack provenance | same | same | `skills/_ml-pack-docs/PROVENANCE.md` |
| engineering workflow (adapted) | `obra/superpowers` (MIT) | upstream main tree `b36e0829c6d0140e93cfef2ca599b1b07d4a7797` at the 2026-09-16 audit; super-* skills are adapted in-repo and diverge | `skills/super-*/` |

### Deliberate omissions

- Devops pack's `security-review` skill — `awesome-security-review` already covers it.
- Devops pack's `examples/` folder — illustrative samples only, no runtime value.
- Upstream container prefixes (`skills/mlops/…`, `skills/llmops/…`) — flattened into the
  flat registry so one directory = one skill, as every wagents script expects.

### Support directories (`_`-prefixed, not skills)

- `skills/_devops-pack-docs/` — contract, finding format, templates. The 12 devops skills
  link to them as `../_devops-pack-docs/<file>`.
- `skills/_ml-pack-docs/` — provenance record for the ML/LLM packs.

Both are skipped by `smoke-skills.sh`, `validate-agent-guide.py`, and the skill counts.

## Updating a vendored set

1. Read upstream changes first (do not blind-update).
2. Delete the old skill directories (and the container, if upstream moved things).
3. Re-vendor and set the new pin:
   - claude-red: delete `vendor/Claude-Red`, then `CLAUDE_RED_REF=<sha> bash scripts/install-base-skills.sh --include-hacker`
   - the rest: copy skill dirs, rename to the group prefix, update the `name:` in each `SKILL.md`
     to match its directory, refresh `PROVENANCE.md`, update `config/skills.json`.
4. Run `bash scripts/verify-install.sh && bash scripts/smoke-skills.sh && python scripts/validate-agent-guide.py`.

## Adding a new skill

1. Add `SKILL.md` under `skills/<group-prefix>-<name>/` (frontmatter `name:` **must equal**
   the directory name; `description:` is required).
2. Add an entry in `config/skills.json` (`name`, `group`, `path`, `source`, `license`, `target_agents`, `status`).
3. Scope it in `config/permissions.json` if the agent needs new tools/MCP.
4. Mention it in the owning agent's `## Skills` section.
5. Run the three verification commands above.

