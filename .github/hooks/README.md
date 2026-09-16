# Hooks — wagents (.github/hooks)

Placeholder for Copilot/VS Code hooks as supported by your client version.

Use this directory for deterministic automation such as:
- pre-commit secret-scan (`scripts/verify-install.sh` secret-scan pattern)
- pre-push verify (`scripts/verify-install.sh`)
- post-merge pinned-ref check (`config/skills.json`, `config/plugins.json`)

Keep hooks small, reviewable, and portability-safe (bash + PowerShell variants).
Do not commit secrets in hooks. Do not auto-attack targets.

See `docs/troubleshooting.md` and `docs/security.md`.
