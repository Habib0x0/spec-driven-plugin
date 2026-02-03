---
name: spec-tasks
description: Regenerate tasks from updated spec requirements and design
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - TaskCreate
  - TaskUpdate
  - TaskList
  - AskUserQuestion
---

# /spec-tasks Command

Regenerate implementation tasks from the current spec requirements and design.

## Workflow

### 1. Identify Current Spec

Look for existing specs in `.claude/specs/`:

If multiple specs exist, ask which one to update. If only one exists, use it automatically.

### 2. Read Current Spec

Read:
- `.claude/specs/<feature-name>/requirements.md`
- `.claude/specs/<feature-name>/design.md`
- `.claude/specs/<feature-name>/tasks.md` (if exists)

### 3. Analyze Changes

If tasks.md exists, compare against requirements and design:

1. Identify new requirements not covered by existing tasks
2. Identify design components without implementation tasks
3. Identify tasks for removed/changed requirements
4. Note completed tasks that should be preserved

### 4. Generate Updated Tasks

Create/update tasks organized by phase:

**Phase 1: Setup**
- Project scaffolding
- Dependencies
- Configuration

**Phase 2: Core Implementation**
- Main feature functionality
- Data models
- Business logic

**Phase 3: Integration**
- API connections
- Service integration
- UI integration

**Phase 4: Testing**
- Unit tests
- Integration tests
- E2E tests

**Phase 5: Polish**
- Error handling
- Edge cases
- Documentation

### 5. Preserve Completed Work

When regenerating tasks:

1. Keep tasks marked as `completed`
2. Update `pending` tasks if requirements changed
3. Mark obsolete tasks as removed with note
4. Add new tasks for new requirements

### 6. Sync to Claude Code Todos

After updating tasks.md:

1. Check existing todos with TaskList
2. Create new todos for new tasks
3. Update existing todos if descriptions changed
4. Do not remove completed todos

### 7. Summary

Provide summary of changes:

- Tasks added: X
- Tasks updated: Y
- Tasks removed: Z
- Total pending tasks: N

## Example Usage

```
/spec-tasks
```

## Tips

- Run this after `/spec-refine` to keep tasks aligned
- Review generated tasks before syncing to todos
- Completed tasks are never automatically removed
- Dependencies are recalculated based on task sequence
