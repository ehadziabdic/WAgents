<div align="center">

<img src="pictures/logo.png" alt="WAgents" width="400"/>

# WAgents

**Turn your home PC into your personal AI crew, reachable from your phone. Chat, speak, or type: it codes, designs, secures, researches, watches your AI training, grabs your files, and talks back. Full remote control over Telegram with voice mode, a complete agent ecosystem for development, security, and design, plus a ready-wired MCP stack. Clone, install, paste one prompt, done.**

*Control your computer from anywhere · Talk instead of typing · AI that designs, codes & guards · Training watched while you sleep*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-pink.svg)](https://github.com/sponsors/ehadziabdic)
[![Coffee](https://img.shields.io/badge/buy%20me%20a-coffee-FFDD00.svg)](https://buymeacoffee.com/ehadziabdic)
![Windows](https://img.shields.io/badge/platform-Windows-lightgrey)
![PowerShell](https://img.shields.io/badge/shell-powershell-blue?logo=powershell&logoColor=white)
[![Host](https://img.shields.io/badge/host-OpenCode%20first-8A2BE2)](#harness-portability)
[![Secrets](https://img.shields.io/badge/secrets-zero%20in%20git-red.svg)](#security-model)

*OpenCode-first · Brave-only · Tailscale-only remote · session-only operation · no secrets in git*

</div>

---

## Table of contents

- [Why WAgents](#why-WAgents)
- [Architecture at a glance](#architecture-at-a-glance)
- [Quick start](#quick-start)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [Phase 0: by hand](#phase-0-by-hand)
  - [Agent-driven install](#agent-driven-install)
- [Post-install configuration](#post-install-configuration)
  - [Secrets you create](#secrets-you-create)
  - [Verify your install](#verify-your-install)
- [MCP catalog](#mcp-catalog)
- [Using it day to day](#using-it-day-to-day)
  - [Telegram remote](#telegram-remote)
  - [How delegation works](#how-delegation-works)
  - [Skills](#skills)
  - [Hacker mode](#hacker-mode-offensive-security)
  - [Training watchers](#training-watchers)
- [Harness portability](#harness-portability)
- [Updating](#updating)
- [Extending WAgents](#extending-WAgents)
- [Security model](#security-model)
- [Repository structure](#repository-structure)
- [Documentation](#documentation)
- [Sponsor](#sponsor)
- [License & acknowledgements](#license--acknowledgements)

---

## Why WAgents

Most AI setups live only on one machine and die with it. WAgents is a
**portable home setup**: every agent, skill, command, MCP connection, watcher,
and automation lives in this repo (secrets excluded), so a fresh Windows PC
becomes your exact environment in minutes instead of a weekend.

| | What you get |
|---|---|
| **3 main agents** | Ask (chat/plan only), Build (implements), Hacker (sole holder of 78 offensive skills) |
| **10 specialists** | frontend, backend, security, reviewer, debugger, QA, research, docs, ML, devops |
| **190+ skills** | `think` workflow family (brainstorm, plan, execute, verify, review), `offensive` library, `taste/UI` design, `office` formats, `LLM/ML/DevOps` packs, `Obsidian`, `Figma/MCP` builders |
| **Telegram remote** | 13 commands + free text and voice that run in chat, screenshots, files both ways, Drive uploads |
| **Training watchers** | SSO-aware JupyterHub poller, heartbeat inbox, hourly retention sweep |
| **MCP stack** | context7, GitHub, Playwright, Notion, Tavily, Sentry, SonarQube, Supabase, Figma, HuggingFace |
| **Zero secrets in git** | installer + agent prompt walk you through creating every key yourself |

---

## Architecture at a glance

Three **main agents** route work; ten **specialists** execute. Mains may delegate; specialists never do.

| Agent | Role | Notes |
|---|---|---|
| `wagent-ask` | **Main**: chat, questions, designs, specs, plans | Never implements; ends at approval gates |
| `wagent` | **Main (default)**: intent, architecture, routing, parallel delegation, integration, validation | Chats and implements |
| `wagent-hacker` | **Main**: authorized offensive security, full engagement driver | Explicit target authorization; exclusive `offensive-*` skills |
| `frontend-designer` | UI/UX, visual hierarchy, accessibility, frontend implementation | |
| `backend-engineer` | APIs, auth, database, business logic, performance | |
| `security-engineer` | Defensive security, threat modeling, scanning | |
| `code-reviewer` | Independent correctness, maintainability, security, tests | Read-only lane |
| `debugger` | Root-cause analysis, minimal fix, regression test | |
| `qa-engineer` | Unit / integration / API / E2E / browser testing | |
| `research-specialist` | Web research, docs verification, evidence-backed recommendations | Read/search only |
| `documentation-specialist` | Diataxis docs, diagrams, slides, vaults, office formats | |
| `ml-engineer` | Python/data, ML experiments, evaluation, RAG/LLM, pipelines | |
| `devops-engineer` | Docker, CI/CD, cloud, deployment, observability | |

Delegation rules: only mains delegate. `wagent` may call every specialist
except `wagent-hacker`; `wagent-hacker` may call every specialist except
`wagent`; mains never call each other; specialists never delegate.
The Ask/Build split is a behavioral contract documented in each agent file.

## Quick start

```powershell
git clone https://github.com/ehadziabdic/WAgents.git; cd WAgents
# 1. Phase 0 in docs/AGENT-SETUP-PROMPT.md (install app, first chat ~10 min)
# 2. Paste the prompt into a new opencode chat, the agent runs install.ps1
```

Plus 4 manual clicks the agent collects in ONE ask (Telegram chat ID,
Hub token, Tailscale approval, voice-session pointer).

---

## Installation

### Prerequisites

| Requirement | Why | Notes |
|---|---|---|
| Windows 10/11 | primary platform | installer is PowerShell, elevated |
| `git` | clone | installer tries winget for the rest |
| Tailscale | the only remote path | phone + PC on the same tailnet |
| Brave | attached-tab driving | debug flag, one-time relaunch |
| Python 3.12+, Node 22+ | bot, transcriber, MCPs, scripts | installer best-effort via winget |

### Phase 0: by hand

Install OpenCode Desktop (`winget install SST.OpenCodeDesktop`), launch
once, `opencode auth login` per account, clone the repo. Details in
[`docs/AGENT-SETUP-PROMPT.md`](docs/AGENT-SETUP-PROMPT.md).

### Agent-driven install

`install.ps1` stages: [0] base tools, [1] config overlay, [2] secrets
scaffolding, [3] firewall scoping (opencode rules to Private-only),
[4] rclone, [5] npm deps, [6] pip + whisper-small prefetch,
[7] rclone binary, [8] credential import helper. Then the manual list
from section 2 of [`docs/SETUP.md`](docs/SETUP.md).

## Post-install configuration

### Secrets you create

| Secret | Where | How |
|---|---|---|
| Provider logins | `opencode auth login` | repeat per account |
| Service password | `service.json` | long random string, yours alone |
| Figma Bearer | `opencode.jsonc` figma-mcp headers | personal access token |
| Drive OAuth | `rclone config` | Google login click in Brave |
| Telegram bot + chat ID | `telegram/.telegram.env` | @BotFather + @userinfobot |
| JupyterHub token | `scripts/.jupyter.env` | Hub Token page, or skip watcher |

### Verify your install

- `opencode session list` works; web UI opens over Tailscale from phone.
- Firewall shows opencode rules Private-only.
- Bot answers `/help`, `/status` works, voice note transcribes.
- Jupyter checker prints live state, never a traceback.

## MCP catalog

Configured in `opencode/opencode.jsonc`, OAuth/tokens created per user:

| Server | Transport | Needs | Used by |
|---|---|---|---|
| `context7` | remote | nothing | all agents, docs lookup |
| `github-mcp-server` | remote | OAuth/PAT in client | backend, security, devops |
| `playwright-mcp` | local (`npx`) | first browser download | frontend, debugger, QA |
| `notion-mcp-server` | remote | OAuth + workspace | mains, docs (read-default) |
| `tavily-mcp` | local (`npx`) | `TAVILY_API_KEY` | research-specialist |
| `sentry-mcp` | local (pinned npm) | `SENTRY_ACCESS_TOKEN` | backend, security, debugger |
| `sonarqube-mcp-server` | local | server URL + token | code-reviewer, security |
| `supabase-mcp` | remote | access token | backend-engineer |
| `figma-mcp` | remote | Bearer token | design-to-code and back |
| `huggingface-mcp` | remote | login | ML/LLM lanes |

## Using it day to day

### Telegram remote

| Command | Purpose |
|---|---|
| `/shot` | desktop screenshot as photo |
| `/status` | CPU/RAM/disk/uptime/GPU/Jupyter one-pager |
| `/ls`, `/get` | browse and receive files (home-jailed, 45 MB cap) |
| `/drive` | upload to Google Drive, replies with link |
| `/zip`, `/unzip` | archive a folder, extract next to it |
| `/clip`, `/clip <text>` | read/set PC clipboard |
| `/upload`, `/photo` | send files/pictures in, saved to inbox |
| `/voice` | talk; local transcription runs it in chat |
| plain text | runs in chat, answer returns to Telegram |
| `/help` | full list, always current |

Voice and free text execute in the main chat session and the answer
comes back to Telegram. Transcription is local (faster-whisper);
audio never leaves the PC.

### How delegation works

1. You talk to **Ask or Build**: intent, questions, architecture.
2. Build dispatches parallel specialists, each scoped to its skills.
3. `code-reviewer` (independent, read-only) reviews; QA tests.
4. Build verifies with evidence and reports what changed.

### Skills

`think-*` is the workflow family (start, brainstorm, plan, execute,
delegate, parallel, tdd, debug, verify, review-ask, review-take,
finish, isolate, forge). Around it: 78 `offensive-*` skills (Hacker
only), taste/UI packs, office formats, LLM/ML/DevOps packs, Obsidian,
Figma/MCP builders. Agents load a skill when its trigger matches.

### Hacker mode (offensive security)

`wagent-hacker` is a separate main agent for **authorized work only**:
owned/local/lab/CTF/staging, or a target you name explicitly. It is the
only agent allowed to load `offensive-*`. The other mains refuse
offensive tasks and route to it.

### Training watchers

`schedules/` holds pollers: JupyterHub server/kernel state (SSO-aware:
quiet when logged out, alerts only on real mid-training changes),
a training-done template, and a heartbeat inbox the bot forwards as
`[auto]` messages. Hourly retention sweep deletes stale non-image
artifacts; phone photos are never touched.

## Harness portability

Built opencode-first, portable by design. The five small seams
(session bridge, session IDs, MCP file, installer, config default)
are documented in [`docs/HARNESS.md`](docs/HARNESS.md) with the exact
per-harness swap for Codex, Claude, and Copilot.

## Updating

Re-pull and re-run `install.ps1` (safe to repeat; secrets files are
never overwritten when already present... verify the prompt before
running on a live machine). Pin a release tag for stable machines.

## Extending WAgents

**Add a skill:** create `opencode/skills/<prefix>-<name>/SKILL.md`
(`name:` must equal the directory name) and reference it from the
owning agent file. **Add an agent:** `opencode/agents/<id>.md`
(`description:` + `mode:`) plus delegation entries in the mains.
**Add a watcher:** copy `schedules/_template/`, emit
`schedules/inbox/*.json`, the bot forwards it.

## Security model

- **No secrets in git.** Verified by pattern sweep before every push.
- **Tailscale-only remote**: firewall allows opencode on Private only.
- **Allowlisted bot**: one Telegram chat ID, everything else ignored.
- **Home-jailed files**: the bot can never serve outside the home dir.
- **Read-only lanes**: reviewer and researcher cannot change anything.
- **Authorization gates**: destructive, deployment, and offensive
  actions require explicit approval, every time.
- **Coordinated disclosure**: see [SECURITY.md](SECURITY.md) to report
  vulnerabilities privately.

## Sponsor

If WAgents saves you time, consider supporting it:

- [GitHub Sponsors](https://github.com/sponsors/ehadziabdic)
- [Buy Me a Coffee](https://buymeacoffee.com/ehadziabdic)

## Repository structure

```text
WAgents/
├── opencode/        agents, skills, command, instructions, schedules,
│                    scripts, opencode.jsonc, service config
├── local-share/     auth.json, mcp-auth.json, account.json (YOU create)
├── telegram/        bot, env templates, operator tools, requirements
├── rclone/          Drive remote notes (config created at install)
├── pictures/        logo + banner
├── docs/            SETUP, AGENT-SETUP-PROMPT, HARNESS, PUBLIC-RELEASE
├── install.ps1      9-stage installer (elevated PowerShell)
├── import-credentials.ps1  private-backfill helper (no-op publicly)
├── AGENTS.md        global rules
└── LICENSE          MIT
```

## Documentation

| Doc | Contents |
|---|---|
| [`docs/SETUP.md`](docs/SETUP.md) | fresh-machine guide + manual steps with reasons |
| [`docs/AGENT-SETUP-PROMPT.md`](docs/AGENT-SETUP-PROMPT.md) | paste-into-chat installer prompt + action-request pattern |
| [`docs/HARNESS.md`](docs/HARNESS.md) | Codex/Claude/Copilot portability seams |
| [`docs/PUBLIC-RELEASE.md`](docs/PUBLIC-RELEASE.md) | how this public tree was stripped (audit trail) |
| [`telegram/README.md`](telegram/README.md) | bot commands and files |

## License & acknowledgements

MIT: see [LICENSE](LICENSE).

Built on the work of these projects (pins live in the vendored sets):

| Project | What we use | License |
|---|---|---|
| [Superpowers](https://github.com/obra/superpowers) (obra) | workflow skills, renamed to the `think-*` family | MIT |
| [Claude-Red](https://github.com/SnailSploit/Claude-Red) (SnailSploit) | `offensive-*` library for the hacker agent | MIT |
| [taste-skill](https://github.com/Leonxlnx) (Leonxlnx) | `taste-*` frontend design skills | MIT |
| [ui-ux-pro-max](https://github.com/nextlevelbuilder) | `ui-ux-*` design skills | MIT |
| [obsidian-skills](https://github.com/kepano) (kepano) | `obsidian-*` vault skills | MIT |
| [Anthropic skills](https://github.com/anthropics/skills) | API, testing, MCP-builder, office formats | Apache-2.0 / source-available |
| [devops-skills](https://github.com/NotHarshhaa) | `devops-*` advisors | MIT |
| [MLOps-agent-skills](https://github.com/timwukp) | `ml-*`, `llm-*`, `model-*`, `data-*` packs | Apache-2.0 |
| [rclone](https://rclone.org) | Drive bridge | MIT |
| [faster-whisper](https://github.com/SYSTRAN/faster-whisper) | local voice transcription | MIT |

<p align="center">
  <img src="pictures/banner.png" alt="WAgents" width="60%" />
</p>

---
