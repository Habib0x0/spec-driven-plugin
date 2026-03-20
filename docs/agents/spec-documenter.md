# spec-documenter

The spec-documenter generates user-facing documentation from spec files and the actual implementation. It runs after features are complete and produces the documentation your users and developers will reference going forward.

## Role

Transform internal spec artifacts and implementation code into accurate, useful documentation targeted at the right audience for each document type.

## Model

**Sonnet.** Documentation generation is synthesis work — read sources, determine what to document, write clearly for the target audience. Sonnet handles this well and produces clean output quickly.

## When It Runs

- `/spec-docs` — invoked explicitly after implementation is complete
- `spec-docs.sh` — called from the post-implementation script pipeline

## What It Does

The documenter reads four sources: `requirements.md` (for user stories, roles, and acceptance criteria), `design.md` (for architecture, endpoints, data models), `tasks.md` (to confirm which features are actually complete), and the implementation code itself (for accurate signatures, types, and real behavior).

It then selects the appropriate document types based on the feature:

| Feature Type | Documents Generated |
|-------------|---------------------|
| API / Backend | API Reference, Architecture Decision Record |
| UI / Frontend | User Guide, Component Reference |
| Full-Stack | All of the above |
| Library / SDK | API Reference, Getting Started Guide |
| Infrastructure | Operations Runbook, Architecture Decision Record |

All output is written to `.claude/specs/<feature-name>/docs/`.

**API Reference** (`api-reference.md`) — Documents each endpoint with request parameters, response schema, error codes, and a realistic example drawn from the actual implementation.

**User Guide** (`user-guide.md`) — Written for end users, derived from requirements user stories. Covers getting started, workflows by user role, common tasks, and troubleshooting.

**Architecture Decision Record** (`adr.md`) — Captures the design decisions made in `design.md`: the context, the chosen approach, alternatives considered, and consequences.

**Operations Runbook** (`runbook.md`) — For infrastructure components: dependencies, configuration, health checks, common issues, and rollback procedures.

## Key Rules

- Uses the actual implementation code as the source of truth, not `design.md`. If they differ, the code wins and the discrepancy is flagged.
- Only documents features whose tasks are marked complete in `tasks.md`. Incomplete features are excluded.
- Checks for existing documentation before writing to avoid duplication or contradiction.
- User guides are non-technical; API references are precise. The audience determines the style.
- Examples are included everywhere — they provide more value than prose descriptions.
