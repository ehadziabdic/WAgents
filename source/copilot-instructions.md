# wagents — Copilot Instructions (Global)

- Prefer evidence over assumptions.
- Inspect existing code before introducing patterns.
- Reuse project conventions; avoid unnecessary dependencies.
- Keep changes small and reviewable.
- Use current docs when API behavior may have changed.
- Do not claim tests passed unless actually run.
- Do not claim security issues without evidence.
- Do not hide errors.
- Do not expose or commit secrets.
- Respect least privilege.
- Destructive, deployment, and offensive-security actions require explicit authorization.
- Prefer deterministic tools over guesses.
- Independent review for substantial changes.
- Preserve reproducibility.

## Routing

- UI/UX/frontend -> frontend-designer
- Architecture/decisions/refactors -> wagent (owns architecture directly)
- Backend/API/DB/auth -> backend-engineer
- Defensive security -> security-engineer
- Offensive testing -> user switches to wagent-hacker (explicit target authorization required; main agents never delegate to each other)
- Review -> code-reviewer
- Failures/root-cause -> debugger
- Testing -> qa-engineer
- Research/current information -> research-specialist
- Documentation/diagrams/office formats -> documentation-specialist
- ML/data/LLM -> ml-engineer
- Docker/CI/CD/infra -> devops-engineer

## Global vs Project

- Global config is reusable. Project config overrides or extends it.
- Do not make global defaults uncustomizable per project.
