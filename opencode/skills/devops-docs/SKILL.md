---
name: devops-docs
description: Shared contract, finding format, plan and investigation templates for the twelve read-only devops advisor skills. Load this before using any devops-* skill that links to ../devops-docs/.
metadata:
  opencode/autoinvoke: false
---

# Devops Shared Docs

Reference material only. This directory holds the documents that the twelve
`devops-*` advisor skills link to instead of restating the same rules in every
file.

## Files

| File | Purpose |
|---|---|
| `skill-contract.md` | Hard rules every devops skill obeys: read-only behaviour, evidence requirements, effort levels, output paths, secret handling, cross-skill routing |
| `finding-format.md` | How a finding is written: severity, evidence, impact, remediation, verification |
| `plan-template.md` | The structure of the remediation plan a skill writes |
| `investigation-template.md` | The structure of a live-incident document |
| `skill-template.md` | Starting point for authoring a new devops skill |

## Usage

Any `devops-*` skill that links `../devops-docs/<file>` expects that file to be
read before the skill proceeds. The contract is authoritative: if a skill's own
wording conflicts with `skill-contract.md`, the contract wins.

These skills are read-only advisors. They investigate, base every finding on a
`file:line` or a command plus its output, and write a plan. They never apply,
deploy, restart, rotate, or delete anything.
