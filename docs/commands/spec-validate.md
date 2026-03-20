# /spec-validate

Validate that a spec is complete, internally consistent, and ready for implementation. Checks requirements structure, design coverage, task traceability, and cross-document consistency.

## Usage

```
/spec-validate
```

No arguments — the command detects available specs and prompts if multiple exist.

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| _(none)_ | — | Interactive. Auto-selects the spec if only one exists. |

## What It Does

1. **Checks file completeness** — verifies that all three spec files exist: `requirements.md`, `design.md`, and `tasks.md`.

2. **Validates requirements** — checks that each user story follows the `As a / I want / So that` format, has at least one acceptance criterion in EARS notation (`WHEN ... THE SYSTEM SHALL ...`), uses specific and testable language (flags vague terms like "quickly", "easily", "properly"), and has no unresolved open questions.

3. **Validates design** — verifies that the design has an architecture overview, component specifications with clear interfaces, and data models. Checks that security and performance considerations are documented, and that all requirements are addressable by the described design.

4. **Validates tasks** — checks that tasks are organized by phase, each has required fields (status, requirements reference, description, acceptance criteria, dependencies), all requirements trace to at least one task, no tasks exist without a requirement link, and task dependencies form a valid graph with no cycles.

5. **Runs cross-reference validation** — verifies that requirement IDs in `tasks.md` match those in `requirements.md`, components referenced in tasks match those in `design.md`, and no contradictions exist between documents.

6. **Produces a validation report** with a PASS/FAIL/WARNINGS status, a list of all issues found, and specific guidance on how to fix each one.

## Example Output

```
## Spec Validation: user-authentication

### Summary
- Status: FAIL
- Issues Found: 1
- Warnings: 1

### Issues to Address

1. [ERROR] Task T-7 missing acceptance criteria
   - File: tasks.md
   - Fix: Add specific, testable acceptance criteria

2. [WARNING] Open question in requirements
   - File: requirements.md
   - Question: "Should we support OAuth?"
   - Action: Resolve before implementation
```

## Tips

- Run this before starting any implementation. Fixing spec problems before coding is much cheaper than fixing them after.
- Address all errors before proceeding. Warnings are advisory but worth reviewing.
- Re-validate after significant spec changes, especially after running `/spec-refine`.
- A PASS result does not guarantee the spec is correct — it confirms it is structurally sound and internally consistent.

!!!tip
    Validation is a fast safety check. It takes seconds and can prevent days of rework from building the wrong thing.

## See Also

- [/spec-refine](spec-refine.md) — Fix requirement or design issues found during validation
- [/spec-tasks](spec-tasks.md) — Fix task traceability issues
- [/spec-exec](spec-exec.md) — Begin implementation after validation passes
