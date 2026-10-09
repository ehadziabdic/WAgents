---
description: Security rules: input validation, auth, least privilege
alwaysApply: true
---
# Security Instructions

- Validate all untrusted inputs at boundaries. Fail closed.
- Use parameterized queries. No string-concatenated SQL or shell.
- Encode output for its context. No unsanitized HTML.
- Check auth on every sensitive path. Deny by default.
- No secrets in code, logs, or git. Use env or secret stores.
- Prefer least privilege. Document assumptions.
