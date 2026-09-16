---
name: base-webapp-testing-basics
description: Web app testing baseline. Use for unit, integration, API, E2E, browser testing. Prefers deterministic realistic checks.
license: MIT
---

# Webapp Testing Basics (wagents original)

## Scope
- Unit, integration, API, E2E, browser, regression.
- Happy path and failure paths.

## Workflow
1. Identify critical flows.
2. Add deterministic tests.
3. Use browser evidence for UI flows where useful.
4. Run tests. Report actual results.
5. Add regression tests for fixes.

## Rules
- No claim of passing without running.
- Keep tests deterministic. No network or time flakes.
- Prefer realistic E2E for critical flows.
