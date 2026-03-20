# Tasks

The tasks phase breaks the design into discrete, trackable implementation items. The spec-tasker agent (Sonnet) generates `tasks.md` and syncs tasks to Claude Code's todo system.

## Task structure

```markdown
### T-1: [Imperative title]

- **Status**: pending
- **Wired**: no
- **Verified**: no
- **Requirements**: US-1, US-2
- **Description**: Detailed description of what to implement
- **Acceptance**:
  - Specific, testable criterion 1
  - Specific, testable criterion 2
- **Dependencies**: T-0 | none
- **Notes**: Optional implementation hints
```

## The three tracking fields

Every task has three fields that together determine whether the task is truly done.

**Status** tracks code existence:
- `pending` — not started
- `in_progress` — currently being implemented
- `completed` — code has been written

**Wired** tracks code reachability:
- `no` — code exists but is not connected to the application
- `yes` — code is reachable from the application's entry points (routes, navigation, API)
- `n/a` — task is infrastructure or config with nothing to wire (database setup, CI config, test writing)

**Verified** tracks end-to-end testing:
- `no` — not yet tested
- `yes` — tested end-to-end and all acceptance criteria pass

A task is only truly done when: `Status: completed` AND `Wired: yes` (or `n/a`) AND `Verified: yes`.

!!!warning
    Marking a task as `Verified: yes` without actual end-to-end testing is not acceptable. Execution scripts explicitly prohibit this.

## Task phases

Tasks are organized into five phases:

### Phase 1: Setup

Project scaffolding, dependencies, and configuration that everything else depends on. Examples: initialize project structure, configure database connection, set up build tooling.

### Phase 2: Core Implementation

The main feature functionality. Examples: create data models, implement API endpoints, build UI components.

### Phase 3: Integration (mandatory)

Wires the core implementation into the running application. Every backend task from Phase 2 that creates new code should have a corresponding integration task here.

The key question for each Phase 2 task: "Can a user reach this feature after Phase 2 alone?" If not, an integration task is required.

Integration task naming convention: start with "Wire", "Connect", "Add [X] to [Y]", or "Register" to make wiring tasks immediately identifiable.

Example integration tasks:
- Wire login form to authentication endpoint
- Add dashboard route and navigation link
- Register webhook handler in the event router

!!!note
    Code that exists but is not reachable from the application is useless. The Integration phase is mandatory, not optional.

### Phase 4: Testing

Unit tests, integration tests, and end-to-end tests. These tasks cover the test suite itself, separate from the per-task verification in the Wired/Verified fields.

### Phase 5: Polish

Error handling for edge cases, logging, rate limiting, monitoring, and cleanup.

## Task sizing

Tasks should be completable in a single work session. A useful size check:

| Size | Description |
|------|-------------|
| XS | Single function or component |
| S | Small feature unit |
| M | Feature slice |
| L | Consider splitting |

If a task description contains "and," consider splitting it into two tasks.

## Dependencies

Every task declares its dependencies explicitly. This enables the execution scripts to respect ordering and prevents starting tasks before their prerequisites are met.

```markdown
- **Dependencies**: T-1, T-2
```

The spec-validator checks for circular dependencies. See [Cross-spec dependencies](../advanced/cross-spec-deps.md) for dependencies between separate specs.

## Summary table

`tasks.md` includes a summary table that tracks counts:

| Status | Count |
|--------|-------|
| Completed | 8 |
| Wired | 6 |
| Verified | 5 |

This makes it immediately clear when tasks are marked completed but not yet wired or verified.

## Regenerating tasks

If requirements or design change significantly, regenerate tasks with:

```
/spec-tasks
```

## Syncing with Claude Code todos

Tasks sync to Claude Code's built-in todo system via `TaskCreate` and `TaskUpdate`. After running execution scripts (which run in a subprocess and cannot call `TaskUpdate` directly), reconcile the two with:

```
/spec-sync
```
