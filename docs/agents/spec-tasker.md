# spec-tasker

The spec-tasker reads a completed spec and breaks it into discrete, trackable implementation tasks. It runs at the end of the `/spec` workflow and whenever you regenerate tasks with `/spec-tasks`.

## Role

Translates `requirements.md` and `design.md` into a structured `tasks.md` and syncs every task to Claude Code's built-in todo system.

## Model

**Sonnet.** Task decomposition is structured, repeatable work. Given a well-formed spec, the breakdown follows clear rules: one task per concern, explicit dependencies, traceable requirements. Sonnet handles this quickly and accurately without needing Opus-level reasoning.

## When It Runs

- `/spec <name>` — automatically invoked as Phase 3, after the planner finishes
- `/spec-tasks` — invoked standalone to regenerate tasks after a spec has been updated

## What It Does

The tasker organizes tasks across five phases:

| Phase | Contents |
|-------|----------|
| 1 — Setup | Scaffolding, dependencies, configuration |
| 2 — Core Implementation | Data models, business logic, backend endpoints, UI components |
| 3 — Integration | Connecting everything — routes, navigation, API wiring |
| 4 — Testing | Unit, integration, and end-to-end tests |
| 5 — Polish | Error handling, edge cases, loading and empty states |

Each task includes: status, a `Wired` field, `Verified` field, linked requirement IDs, a description, acceptance criteria, and dependencies.

The `Wired` field tracks whether code is reachable from the application's entry points (`no`, `yes`, or `n/a` for infrastructure tasks).

After writing `tasks.md`, the tasker calls `TaskCreate` for each task and sets up blocking relationships via `TaskUpdate`, making all tasks visible in Claude Code's todo panel.

## Key Rules

- The Integration phase (Phase 3) is mandatory and must never be skipped. For every core implementation task, the tasker asks: "Can a user reach this feature after this task is done?" If not, an integration task is required.
- Every task must link to at least one requirement from `requirements.md`.
- Dependencies must form a valid DAG — no circular dependencies.
- Acceptance criteria must be specific: "The Settings page is accessible by clicking Settings in the sidebar navigation" rather than "feature is integrated."
