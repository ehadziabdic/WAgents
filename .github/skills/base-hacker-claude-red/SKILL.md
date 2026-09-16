---
name: base-hacker-claude-red
description: Exclusive authorized offensive security skillset for the wagent-hacker agent only. Full vendored copy of SnailSploit/Claude-Red (78 skills, 22 categories) at a pinned commit. Requires explicit target authorization before any offensive action.
license: upstream MIT — see vendor/Claude-Red/LICENSE
---

# Claude-Red — Vendored Offensive Skillset (Exclusive to wagent-hacker)

This skill indexes the **full vendored copy** of [SnailSploit/Claude-Red](https://github.com/SnailSploit/Claude-Red) located at:

```
.github/skills/base-hacker-claude-red/vendor/Claude-Red/
├── Skills/<category>/<skill-name>/SKILL.md   ← 78 skills, 22 categories
├── tools/          ← upstream helper tooling
├── claude-skills.json
├── MINDMAP.md      ← visual map of the whole library
├── LICENSE         ← MIT (attribution preserved)
└── README.md
```

Provenance and pinned commit: `../vendor/PROVENANCE.md`.

## How to use

1. **Authorization gate first** (see `wagent-hacker` agent). No offensive action without explicit, scoped authorization.
2. Identify the attack surface in scope and pick the matching category below.
3. **Read the specific `Skills/<category>/<skill>/SKILL.md`** before acting on that surface — it primes the methodology, tooling, edge cases, and escalation paths.
4. Combine adjacent skills when an engagement crosses surfaces (e.g. `recon` → `web` → `privesc` → `post-exploitation` → `utility/offensive-reporting`).

## Category index (78 skills)

| Category | Skills |
|---|---|
| **web** (16) | offensive-business-logic, offensive-deserialization, offensive-file-upload, offensive-graphql, offensive-idor, offensive-open-redirect, offensive-parameter-pollution, offensive-race-condition, offensive-rce, offensive-request-smuggling, offensive-sqli, offensive-ssrf, offensive-ssti, offensive-waf-bypass, offensive-xss, offensive-xxe |
| **wireless** (14) | offensive-bluetooth-ble, offensive-bluetooth-classic, offensive-deauth-disassoc, offensive-evil-twin, offensive-krack-fragattacks, offensive-lorawan-sub-ghz, offensive-wifi, offensive-wifi-recon, offensive-wpa-enterprise, offensive-wpa2-psk, offensive-wpa3-sae, offensive-wps, offensive-z-wave, offensive-zigbee-thread-matter |
| **infrastructure** (7) | offensive-advanced-redteam, offensive-edr-evasion, offensive-initial-access, offensive-keylogger-arch, offensive-shellcode, offensive-windows-boundaries, offensive-windows-mitigations |
| **exploit-dev** (6) | offensive-basic-exploitation, offensive-crash-analysis, offensive-exploit-dev-course, offensive-exploit-development, offensive-mitigations, offensive-toctou |
| **fuzzing** (4) | offensive-bug-identification, offensive-fuzzing, offensive-fuzzing-course, offensive-vuln-classes |
| **post-exploitation** (3) | offensive-data-exfiltration, offensive-lateral-movement, offensive-persistence |
| **api** (2) | offensive-api-abuse, offensive-api-security |
| **auth** (2) | offensive-jwt, offensive-oauth |
| **cicd** (2) | offensive-cicd-pipeline, offensive-cicd-secrets |
| **container** (2) | offensive-container-escape, offensive-k8s-attacks |
| **crypto** (2) | offensive-crypto-attacks, offensive-tls-attacks |
| **forensics** (2) | offensive-anti-forensics, offensive-c2-frameworks |
| **privesc** (2) | offensive-linux-privesc, offensive-windows-privesc |
| **recon** (2) | offensive-osint, offensive-osint-methodology |
| **social-engineering** (2) | offensive-phishing, offensive-social-engineering |
| **supply-chain** (2) | offensive-dependency-confusion, offensive-supply-chain |
| **utility** (2) | offensive-fast-checking, offensive-reporting |
| **active-directory** (1) | offensive-active-directory |
| **ai** (1) | offensive-ai-security |
| **cloud** (1) | offensive-cloud |
| **iot** (1) | offensive-iot |
| **mobile** (1) | offensive-mobile |
| **network** (1) | offensive-network-attacks |

## Guardrails

- Only `wagent-hacker` may use the vendored skills. No other agent may read or execute them.
- Never remove or edit `LICENSE`, `PROVENANCE.md`, or the pinned vendor contents when updating.
- To update the vendor copy: delete `vendor/Claude-Red`, optionally set `CLAUDE_RED_REF=<new-commit>`, and re-run `scripts/install-base-skills.sh --include-hacker`.
