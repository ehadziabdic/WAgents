---
description: Orchestrate specialist subagents to execute an approved implementation plan with TDD and verification.
---

# Execute Command (`/wagents-execute`)

Direct the primary orchestrator to execute an approved plan by dispatching tasks to specialist subagents in parallel or sequence.

## Execution Rules

1. **Follow the Approved Plan**: Execute one task at a time. Do not jump ahead or combine steps without explicit reason.
2. **Dispatch to Specialists**:
   - Invoke the designated specialist agent for each domain.
   - Provide the specialist with clear task context, relevant files, and acceptance criteria.
3. **Enforce TDD**: Require specialists to write failing tests before writing production implementation.
4. **Continuous Integration**: Verify each task immediately upon specialist completion. Run automated tests to catch regressions instantly.
5. **Report Progress**: Check off completed items in the plan task list after verification passes.

User input: $ARGUMENTS

