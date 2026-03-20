---
name: spec-sync
description: Sync tasks.md status back to Claude Code task list
allowed-tools:
  - Read
  - Glob
  - Grep
  - TaskList
  - TaskUpdate
  - TaskCreate
---

# /spec-sync Command

Reconcile the Claude Code task list with the current state of tasks.md. This fixes the drift caused by spec-exec/spec-loop/spec-team updating tasks.md in a subprocess that can't call TaskUpdate.

## When to Use

Run this after `/spec-exec`, `/spec-loop`, or `/spec-team` to bring the Claude Code task list up to date with tasks.md.

## Workflow

### 1. Identify Spec

Look for specs in `.claude/specs/`. If multiple exist, ask which one. If one exists, auto-select.

### 2. Parse tasks.md

Read `.claude/specs/<name>/tasks.md` and extract for each task:
- Task ID (T-1, T-2, etc.)
- Task title (from `### T-N: <title>` heading)
- Status (pending, in_progress, completed)
- Verified (yes/no)

### 3. Get Current Task List

Call TaskList to get all Claude Code tasks with their current statuses.

### 4. Match and Sync

For each task in tasks.md, find the matching Claude Code task by subject (match on the task title text). Then:

- If tasks.md says `completed` + `Verified: yes` and Claude Code says `pending` or `in_progress` -> TaskUpdate to `completed`
- If tasks.md says `in_progress` and Claude Code says `pending` -> TaskUpdate to `in_progress`
- If tasks.md says `pending` and Claude Code says `completed` -> Flag as inconsistency (tasks.md is source of truth, but don't downgrade completed tasks — warn instead)
- If a task exists in tasks.md but not in Claude Code -> TaskCreate it with the correct status

### 5. Report

Output a summary:
```
Sync complete: <name>
  Updated: N tasks
  Already in sync: M tasks
  Created: P tasks (missing from task list)
  Warnings: Q inconsistencies
```

List each change made.

## Example Usage

```
/spec-sync
```
