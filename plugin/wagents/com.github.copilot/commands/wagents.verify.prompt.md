---
name: wagents-verify
description: "Run automated test suites, type checks, linting, and build validation before declaring work complete."
argument-hint: "[optional scope or test path]"
---

# Verify Command (`/wagents-verify`)

Enforce the verification-before-completion protocol across unit, integration, and build pipelines.

## Verification Checklist

1. **Test Execution**: Run full project test runner (`npm test`, `pytest`, etc.). Confirm zero failures.
2. **Type Check**: Execute compiler static checks (`tsc --noEmit`, `mypy`). Ensure zero errors.
3. **Build Check**: Validate production bundling/compilation.
4. **Diff Inspection**: Check `git status` and `git diff` for stray files, debug logs, or exposed keys.
5. **Report**: Summarize passed checks and evidence in the completion message.

