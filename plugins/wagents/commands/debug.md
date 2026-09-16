---
description: "Perform systematic root-cause debugging on an active error, test failure, or unexpected behavior."
argument-hint: "[error message or reproduction command]"
---

# Debug Command (`/wagents:debug`)

Invoke the `debugger` specialist to trace and eliminate bugs without guesswork.

## Debugging Protocol

```text
Symptom -> Reproduce -> Collect Evidence -> Form Hypothesis -> Test Hypothesis -> Root Cause -> Minimal Safe Fix -> Regression Test
```

1. **Reproduce First**: Write an automated reproduction test that triggers the bug reliably.
2. **Gather Concrete Evidence**: Inspect logs, stack traces, AST call paths, and variable states. Never guess.
3. **Trace Root Cause**: Distinguish the immediate symptom from the underlying defect.
4. **Minimal Safe Fix**: Apply the smallest surgical correction necessary. Avoid wide-ranging unrelated refactors.
5. **Add Regression Test**: Ensure the reproduction test passes and is permanently committed to prevent regressions.

