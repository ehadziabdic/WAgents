# Security — wagents

## Rules

- No secrets in git. Env only. See `.env.example`.
- Least privilege per `config/permissions.json`.
- Destructive, deployment, and offensive-security actions require explicit authorization.
- Offensive security only via `wagent-hacker` with explicit per-target authorization.
- Allowed hacker targets: owned systems, local environments, labs/CTFs, staging, explicitly authorized targets.
- Forbidden: arbitrary third-party targets, silent destructive/exfiltration, secret commits.
- `wagent` and `wagent-hacker` never call each other — the user picks the lane.

## Agent privilege

- `security-engineer`: read/search, scanning tools. No offensive actions.
- `wagent-hacker`: read/search + exclusive `base-hacker-claude-red` (78 skills; ships in the
  full bundle — this is a personal-use repository). Authorization gate mandatory.
- `code-reviewer`: read/search only. No edit/deploy.
- `research-specialist`: read/search only. No edit/deploy.
- `devops-engineer`: infra/cloud tools only when explicitly enabled. No deploy without approval.

See `config/permissions.json` for full matrix.

## MCP review checklist

For each server in `mcp/servers.json`:

- prompt injection surface
- tool poisoning / dynamic tool changes
- confused deputy behavior
- credential/token exposure
- excessive permissions
- unsafe remote servers
- supply-chain concerns (package, version, maintainer)
- version pinning and update policy

Consider isolation/governance (e.g. ToolHive) if appropriate. Verify current advisories before adoption.

## Workflow

```text
threat model
-> static analysis (Semgrep, SonarQube)
-> dependency/container scan (Trivy)
-> code review (code-reviewer + security-engineer)
-> targeted testing (authorized only)
-> verify remediation
```

## Secrets

- Local: `.env` (ignored), OS credential store, provider auth.
- CI: GitHub secrets.
- Never log credentials. Never commit `.env`, `*.pem`, `*.key`, `credentials.json`.
- `scripts/verify-install.sh` runs secret-scan for `sk-ant-`, `ghp_`, `github_pat_`, `AKIA`.

## Reporting

- Do not claim security issue without evidence.
- Distinguish blocking vs non-blocking.
- Log scope, authorization, findings for hacker runs.
