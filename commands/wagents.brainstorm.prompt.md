---
name: wagents:brainstorm
description: "Refine a user request into a clear technical specification through interactive brainstorming and trade-off analysis."
argument-hint: "[optional topic, feature idea, or problem statement]"
---

# Brainstorming Command (`/wagents:brainstorm`)

Transform rough ideas or underspecified requirements into a robust, agreed-upon technical specification before writing code.

## Operating Rules

1. **One Question at a Time**: Never overwhelm the user with a massive multi-part questionnaire. Ask the single most critical clarifying question first.
2. **Explore Alternatives**: Propose 2–3 viable architectural or implementation approaches with pros, cons, and complexity trade-offs.
3. **Probe Edge Cases**: Surface data validation, authentication, scale, error recovery, and UI states.
4. **Hard Gate**: **NEVER** write implementation code or modify project files while in the brainstorming phase.
5. **Output**: Conclude with a clear, concise specification ready for `/wagents:plan`.

