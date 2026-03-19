---
name: spec-status
description: Show status and progress of current spec
allowed-tools:
  - Read
  - Glob
  - TaskList
---

# /spec-status Command

Display the current status and progress of a spec.

## Workflow

### 1. Identify Specs

Look for existing specs in `.claude/specs/`:

If multiple specs exist, show status for all or ask which one to detail.

### 2. Read Spec Files

For each spec, read:
- `requirements.md` - count user stories AND parse `## Depends On` section for dependency names
- `design.md` - verify exists
- `tasks.md` - count and categorize tasks

**Dependency Parsing**: Look for a `## Depends On` section in requirements.md. Extract each `- <spec-name>` bullet as a dependency. If the section is absent or contains only comments, the spec has no dependencies.

### 3. Calculate Progress

Parse tasks.md to count:
- Total tasks
- Pending tasks
- In-progress tasks
- Completed tasks (Status: completed)
- Wired tasks (Wired: yes)
- Verified tasks (Verified: yes)
- Completion percentage (based on verified, not just completed)

**Important**: A task is only truly "done" when it is completed AND wired AND verified. Display this distinction clearly.

### 4. Check Todo Sync

Compare tasks.md with Claude Code todos (TaskList):
- Are all tasks synced?
- Are statuses in sync?
- Any orphaned todos?

### 5. Display Status

Output a formatted status report:

```
## Spec Status: <feature-name>

### Overview
- Requirements: X user stories
- Design: Complete / In Progress / Missing
- Tasks: Y total

### Progress
| Status | Count | Percentage |
|--------|-------|------------|
| Verified (done) | Z | ZZ% |
| Wired (not verified) | A | AA% |
| Completed (not wired) | B | BB% |
| In Progress | C | CC% |
| Pending | D | DD% |

### Progress Bar
[████████░░░░░░░░] 50% verified

### Integration Health
- Tasks completed but NOT wired: X (these need wiring!)
- Tasks wired but NOT verified: Y (these need testing!)

### Current Focus
- In Progress: T-5: Implement authentication endpoint

### Blocked Tasks
- T-8: Integration tests (blocked by T-5, T-6)

### Dependencies
- auth-system: COMPLETE (10/10 verified) [does not block execution]
- database-migrations: INCOMPLETE (3/5 verified) [BLOCKS EXECUTION]

### Unwired Tasks (Action Needed)
- T-3: Create user profile component (Status: completed, Wired: no)
  -> Needs: Route registration, navigation link

### Next Up
- T-6: Create session management
- T-7: Implement logout endpoint
```

### 6. Check Cross-Spec Dependencies

If the `## Depends On` section from step 2 yielded dependency names:

For each dependency spec name:
1. Check if `.claude/specs/<dep-name>/` exists. If not, report it as "NOT FOUND".
2. If it exists, read its `tasks.md` and count:
   - Total tasks (any `### T-N:` heading)
   - Verified tasks (Status: completed AND Wired: yes/n/a AND Verified: yes)
3. If all tasks are verified, the dependency is COMPLETE. Otherwise, INCOMPLETE.
4. An INCOMPLETE or NOT FOUND dependency BLOCKS EXECUTION (spec-exec, spec-loop, spec-team will refuse to run).

Display the `### Dependencies` section (from the output format in step 5) only if the spec has at least one dependency. Omit it entirely if there are no dependencies.

### 7. Recommendations

Based on status, suggest next actions:

- If any cross-spec dependency is incomplete: "Dependency <name> is incomplete (<N>/<M> verified). Complete it before running execution scripts."
- If any cross-spec dependency is not found: "Dependency <name> not found. Create the spec or remove it from the Depends On section."
- If tasks are completed but not wired: "T-X is completed but not wired into the app. Wire it before moving on."
- If tasks are wired but not verified: "T-X is wired but not verified. Run tests to confirm it works."
- If no in-progress tasks: "Consider starting T-X next"
- If blocked tasks: "Complete T-Y to unblock T-Z"
- If all verified: "Spec complete! Consider running /spec-validate"

## Example Usage

```
/spec-status
```

## Tips

- Run periodically to track progress
- Pay attention to "Unwired Tasks" -- these are the root cause of features not working
- Check for blocked tasks that need attention
- Verify todo sync is maintained
- A task marked "completed" but not "wired" is NOT done
