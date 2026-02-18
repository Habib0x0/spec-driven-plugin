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
- `requirements.md` - count user stories
- `design.md` - verify exists
- `tasks.md` - count and categorize tasks

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

### Unwired Tasks (Action Needed)
- T-3: Create user profile component (Status: completed, Wired: no)
  -> Needs: Route registration, navigation link

### Next Up
- T-6: Create session management
- T-7: Implement logout endpoint
```

### 6. Recommendations

Based on status, suggest next actions:

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
