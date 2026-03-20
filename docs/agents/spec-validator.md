# spec-validator

The spec-validator checks a spec for completeness, internal consistency, and implementation readiness. It is the pre-flight check before implementation begins.

## Role

Verify that `requirements.md`, `design.md`, and `tasks.md` are well-formed, consistent with each other, and free of gaps that would cause problems during implementation.

## Model

**Sonnet.** Validation is checklist-based: verify file structure, check notation, cross-reference IDs, detect cycles in dependency graphs. This is precise, systematic work that Sonnet performs quickly.

## When It Runs

- `/spec-validate` — invoked explicitly by the user at any point in the workflow
- Commonly run after the spec is complete and before starting implementation

## What It Does

The validator works through five checks in sequence:

**File completeness** — Confirms that all three spec documents exist. Missing files are reported as critical errors.

**Requirements validation** — Verifies that each user story follows the As a / I want / So that format, and that every acceptance criterion uses EARS notation (`WHEN [condition] THE SYSTEM SHALL [behavior]`). Flags vague terms ("quickly", "easily", "properly") that make criteria untestable.

**Design validation** — Confirms an architecture overview exists, components are well-defined, data models are specified, and security considerations are documented. Checks that every requirement can be traced to a design element.

**Tasks validation** — Verifies that each task has all required fields, that every requirement has at least one corresponding task, and that task dependencies form a valid DAG with no circular references.

**Cross-reference check** — Compares IDs across all three documents: requirement IDs referenced in tasks must exist in requirements, design components must be covered by tasks, and there should be no orphaned tasks without a requirement link.

## Key Rules

- Issues are classified as errors (must fix before implementation), warnings (should review), or info (suggestions).
- Missing files, untraceable requirements, and circular dependencies are always errors.
- Vague language in acceptance criteria is an error, not a warning.
- If the spec directory does not exist, the validator reports a critical error and recommends running `/spec` first.
- Validates existing files even when some are missing — partial validation is better than none.
