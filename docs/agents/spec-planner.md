# spec-planner

The spec-planner transforms your feature idea into a formal specification. It runs during the `/spec` command and is responsible for the first two phases of the workflow: Requirements and Design.

## Role

Converts user answers and codebase context into a complete, rigorous spec — user stories with EARS acceptance criteria (`requirements.md`) and a technical architecture document (`design.md`).

## Model

**Reasoning tier.** The planner uses the most capable model because requirements and design are where mistakes are most expensive. The reasoning tier carefully analyzes edge cases, failure modes, security considerations, and architectural tradeoffs that a faster model is more likely to miss. A well-constructed spec written by a strong reasoner means fewer surprises during implementation.

## When It Runs

- `/spec <name>` — automatically invoked for Phase 1 (Requirements) and Phase 2 (Design)
- `/spec-refine` — invoked when updating existing requirements or design

## What It Does

**Phase 1 — Requirements**
