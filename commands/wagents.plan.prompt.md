---
name: wagents:plan
description: "Decompose a feature, refactor, or bug fix into an actionable, bite-sized implementation plan."
argument-hint: "[optional specification or goal]"
---

# Plan Command (`/wagents:plan`)

Break a technical specification into small, isolated, and testable tasks with designated specialist subagents.

## Planning Rules

1. **Bite-Sized Increments**: Each step in the plan must represent 2–10 minutes of execution work that can be independently verified.
2. **Specialist Assignment**: Map each task to the optimal specialist:
   - `frontend-designer` for UI, styles, interactions, accessibility
   - `backend-engineer` for endpoints, schemas, database, services
   - `security-engineer` for threat modeling and authz audits
   - `qa-engineer` for test suites and browser coverage
   - `wagent` for component boundaries and cross-cutting concerns (handled directly)
3. **Explicit Verification Steps**: Every task must define its automated test command or verification criteria.
4. **Order by Dependency**: Core schemas and interfaces come first; dependent implementations follow.
5. **Approval Gate**: Stop and wait for user sign-off on the plan before launching implementation.

