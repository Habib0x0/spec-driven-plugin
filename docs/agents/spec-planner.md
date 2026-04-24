# spec-planner

The spec-planner transforms your feature idea into a formal specification. It runs during the `/spec` command and is responsible for the first two phases of the workflow: Requirements and Design.

## Role

Converts user answers and codebase context into a complete, rigorous spec — user stories with EARS acceptance criteria (`requirements.md`) and a technical architecture document (`design.md`).

## Model

**opus tier.** The planner uses the most capable model because requirements and design are where mistakes are most expensive. Opus reasons carefully about edge cases, failure modes, security considerations, and architectural tradeoffs that a faster model is more likely to miss. A well-constructed spec written by a strong reasoner means fewer surprises during implementation.

## When It Runs

- `/spec <name>` — automatically invoked for Phase 1 (Requirements) and Phase 2 (Design)
- `/spec-refine` — invoked when updating existing requirements or design

## What It Does

**Phase 1 — Requirements**

The planner reads your answers from the `/spec` interview and writes user stories in standard format (As a / I want / So that), with every acceptance criterion expressed in EARS notation:

```
WHEN [condition]
THE SYSTEM SHALL [behavior]
```

It actively looks for gaps: error handling you didn't mention, security implications, performance needs, and accessibility requirements. Everything is specific and testable — no vague terms like "quickly" or "properly."

Output: `.claude/specs/<feature-name>/requirements.md`

**Phase 2 — Design**

Starting from the completed requirements, the planner produces a technical design covering component architecture, data models, API contracts, and sequence diagrams for key flows. It considers security at every layer, documents failure modes and recovery strategies, and records alternatives considered with reasoning for the chosen approach.

Output: `.claude/specs/<feature-name>/design.md`

## Key Rules

- Does not ask clarifying questions — all input is gathered upfront by the `/spec` command before the planner is invoked.
- Every requirement must be traceable to a design element. The planner enforces this before finishing.
- Security considerations must be explicit in the design, not left as assumptions.
- No vague or non-testable language anywhere in either document.
