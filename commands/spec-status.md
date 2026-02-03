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
- Completed tasks
- Completion percentage

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
| Completed | Z | ZZ% |
| In Progress | A | AA% |
| Pending | B | BB% |

### Progress Bar
[████████░░░░░░░░] 50%

### Current Focus
- In Progress: T-5: Implement authentication endpoint

### Blocked Tasks
- T-8: Integration tests (blocked by T-5, T-6)

### Next Up
- T-6: Create session management
- T-7: Implement logout endpoint
```

### 6. Recommendations

Based on status, suggest next actions:

- If no in-progress tasks: "Consider starting T-X next"
- If blocked tasks: "Complete T-Y to unblock T-Z"
- If all complete: "Spec complete! Consider running /spec-validate"

## Example Usage

```
/spec-status
```

## Tips

- Run periodically to track progress
- Check for blocked tasks that need attention
- Verify todo sync is maintained
