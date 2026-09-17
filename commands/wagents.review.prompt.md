---
name: wagents:review
description: "Trigger an independent, adversarial code review of recent changes focusing on correctness, security, and maintainability."
agent: code-reviewer
argument-hint: "[optional PR, commit, or branch]"
---

# Review Command (`/wagents:review`)

Invoke the `code-reviewer` agent with fresh context to audit uncommitted changes or a feature branch.

## Review Focus Areas

1. **Correctness**: Logic errors, off-by-one bugs, race conditions, edge case mishandling.
2. **Security**: OWASP Top 10 vulnerabilities, injection flaws, insecure deserialization, credential leakage.
3. **Architecture & Clean Code**: Single-responsibility adherence, unnecessary coupling, clear naming.
4. **Test Coverage**: Are all failure paths tested? Are tests deterministic?
5. **Categorized Findings**: Group issues into **Critical (blocking)**, **Major (should fix)**, and **Minor / Nitpick**.

