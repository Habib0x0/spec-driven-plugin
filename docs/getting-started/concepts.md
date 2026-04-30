# Concepts

This page explains the core ideas behind the plugin: EARS notation, spec file structure, task lifecycle, and model routing.

## EARS notation

All acceptance criteria are written in EARS (Easy Approach to Requirements Syntax). EARS requirements are structured so they are unambiguous and directly testable.

The core pattern:

```
WHEN [condition or trigger]
THE SYSTEM SHALL [expected behavior]
```

**Example:**

```
WHEN a user submits a login form with valid credentials
THE SYSTEM SHALL authenticate the user and redirect to the dashboard
```

EARS has several variations for different situations:

| Pattern | Used for | Example keyword |
|---------|----------|-----------------|
| Event-driven | Behavior triggered by a specific event | `WHEN` |
| State-driven | Behavior that applies while a condition holds | `WHILE` |
| Conditional | Behavior that depends on a prerequisite state | `IF ... WHEN` |
| Ubiquitous | Behavior that always applies | _(no keyword)_ |
| Negative | Behavior that must never occur | `SHALL NOT` |
| Optional | Behavior that may be implemented | `MAY` |

EARS requirements must be specific and measurable. Vague terms like "quickly" or "properly" are rejected by the spec-validator.

See [Requirements](../workflow/requirements.md) for detailed patterns and examples.

## Spec file structure

When you run `/spec <feature-name>`, the plugin creates three files in your project:

```
.claude/specs/<feature-name>/
├── requirements.md   -- user stories with EARS acceptance criteria
├── design.md         -- architecture, components, data models, API contracts
└── tasks.md          -- trackable implementation tasks
```

These files are the source of truth for the spec. Execution scripts read them each iteration; the spec-validator checks them for consistency; the acceptor traces requirements to tasks.

A fourth file, `progress.md`, is created automatically when you run `spec-loop.sh`. It is an append-only session log that tracks what happened in each iteration.

## Task lifecycle

Each task in `tasks.md` has three tracking fields:

| Field | Values | Meaning |
|-------|--------|---------|
| Status | `pending`, `in_progress`, `completed` | Whether the code has been written |
| Wired | `no`, `yes`, `n/a` | Whether the code is reachable from the application |
| Verified | `no`, `yes` | Whether the feature has been tested end-to-end |

A task is only truly done when all three conditions are met: `Status: completed`, `Wired: yes` (or `n/a` for infrastructure tasks), and `Verified: yes`.

The lifecycle:

```
pending
  -> in_progress (implementation started)
  -> completed (code written)
     -> Wired: yes (connected to app — routes registered, navigation linked, etc.)
     -> Verified: yes (tested end-to-end with Playwright or test suite)
```

The `tasks.md` summary table tracks counts for each field, making it immediately visible when tasks are "completed" on paper but not actually working in the application.

Tasks sync to Claude Code's built-in todo system via `TaskCreate` and `TaskUpdate` when a spec is created. After running execution scripts, use `/spec-status` to check current task state.

## Model routing

The plugin automatically selects the appropriate model for each phase. You do not need to switch models manually.

| Agent | Model | Phase | Rationale |
|-------|-------|-------|-----------|
| spec-planner | opus tier | Requirements + Design | Deep reasoning for edge cases, security, architecture |
| spec-tasker | sonnet tier | Task breakdown | Fast, structured decomposition |
| spec-validator | sonnet tier | Validation | Checklist-based verification |
| spec-implementer | sonnet tier | Implementation | Writes code for tasks |
| spec-tester | sonnet tier | Testing | Verifies with Playwright/tests |
| spec-reviewer | opus tier | Review | Code quality, security, architecture |
| spec-consultant | sonnet tier | Consultation | Domain expert analysis during brainstorming |
| spec-acceptor | sonnet tier | Acceptance | Requirement traceability, formal sign-off |
| spec-documenter | sonnet tier | Documentation | Generates docs from spec and code |
| spec-debugger | haiku tier | Debugging | Fixes issues when rejected |
| spec-scanner | sonnet tier | Profile scan | Detects framework, patterns, entities, and registration points |

The opus tier is used where careful reasoning matters most (planning and review). The sonnet tier handles the high-frequency work (implementation, testing, documentation). The haiku tier handles targeted debug fixes. Each agent's tier can be overridden per-environment via `SPEC_MODEL_*` variables — see [model-routing](../advanced/model-routing.md).
