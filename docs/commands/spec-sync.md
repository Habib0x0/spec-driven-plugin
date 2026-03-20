# /spec-sync

Reconcile the Claude Code task list with the current state of `tasks.md`. Fixes status drift that occurs when implementation scripts update `tasks.md` in a subprocess.

## Usage

```
/spec-sync
```

No arguments — the command detects available specs and prompts if multiple exist.

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| _(none)_ | — | Interactive. Auto-selects the spec if only one exists. |

## When to Use

Run this after `/spec-exec`, `/spec-loop`, or `/spec-team` completes. Those commands update `tasks.md` directly but cannot update the Claude Code task list from within the subprocess. `/spec-sync` brings the two back into alignment.

## What It Does

1. **Identifies the spec** — finds specs in `.claude/specs/`. Auto-selects if only one exists.

2. **Parses `tasks.md`** — extracts each task's ID, title, status (pending/in_progress/completed), and verification state.

3. **Reads the current task list** — fetches all Claude Code tasks with their current statuses.

4. **Matches and syncs** — for each task in `tasks.md`, finds the corresponding Claude Code task by title and updates its status:
   - `tasks.md` says completed + verified, Claude Code says pending → update to completed
   - `tasks.md` says in_progress, Claude Code says pending → update to in_progress
   - Task exists in `tasks.md` but not in Claude Code → create it with the correct status
   - `tasks.md` says pending but Claude Code says completed → flag as inconsistency (does not downgrade)

5. **Reports results** — lists every change made, how many tasks were already in sync, how many were created, and any inconsistencies found.

## Example

```
/spec-sync

Sync complete: user-authentication
  Updated: 3 tasks
  Already in sync: 5 tasks
  Created: 0 tasks
  Warnings: 0 inconsistencies
```

## Tips

- Run this as a routine step after any implementation session that used a script-based command.
- `tasks.md` is the source of truth. The Claude Code task list follows it, not the other way around.
- Inconsistency warnings (where Claude Code shows completed but `tasks.md` shows pending) are flagged but not automatically resolved — review them manually.

## See Also

- [/spec-status](spec-status.md) — View overall progress after syncing
- [/spec-exec](spec-exec.md) — Single-task implementation (requires sync afterward)
- [/spec-loop](spec-loop.md) — Loop implementation (requires sync afterward)
- [/spec-team](spec-team.md) — Team-based implementation (requires sync afterward)
