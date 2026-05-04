---
name: spec-bugfix
description: Start a new bugfix spec with structured bug analysis, design, and tasks
argument-hint: "<bug-name>"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - AskUserQuestion
  - Task
---

# /spec-bugfix Command

Guide a bugfix through a three-phase workflow: Bug Analysis, Design, and Tasks.

Unlike feature specs which start from requirements, bugfix specs start from a documented defect and work toward a surgical fix with regression prevention.

## Usage

```
/spec-bugfix <bug-name>
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `bug-name` | Yes | A short, kebab-case identifier for the bugfix. Used as the directory name. |

## Workflow

### Phase 1: Bug Analysis

The agent guides the user through documenting the defect:

1. **Current Behavior (Defect)** — `WHEN [condition] THEN the system [incorrect behavior]`
2. **Expected Behavior (Correct)** — `WHEN [condition] THEN the system SHALL [correct behavior]`
3. **Unchanged Behavior (Regression Prevention)** — `WHEN [condition] THEN the system SHALL CONTINUE TO [existing behavior]`
4. **Reproduction Steps** — exact steps to reproduce the defect
5. **Constraints** — code that must not be modified, backward-compat requirements, etc.

The agent also performs automated root cause analysis by exploring the codebase around the defect.

Output: `bugfix.md`

### Phase 2: Design

The agent proposes a fix approach:

- Root cause summary
- Proposed fix with minimal blast radius
- Test properties to verify (reproducible, fixed, no regression)
- Risk assessment

Output: `design.md`

### Phase 3: Tasks

The agent breaks the fix into discrete tasks:

- Reproduction test (confirms the bug exists)
- Fix implementation (surgical change)
- Regression tests (verify unchanged behavior still works)
- Validation (confirm all three test properties pass)

Output: `tasks.md`

## Directory Structure

```
.claude/specs/<bug-name>/
  bugfix.md      # Bug analysis with current/expected/unchanged behavior
  design.md      # Fix approach and test properties
  tasks.md       # Discrete implementation tasks
```

## Tips

- Be explicit about what code must NOT change — constraints prevent over-fixing
- Document unchanged behavior carefully — this is what prevents regressions
- The reproduction test should fail before the fix and pass after
- Keep the fix surgical; resist the urge to refactor surrounding code
