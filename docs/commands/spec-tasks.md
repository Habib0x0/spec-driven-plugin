# /spec-tasks

Regenerate implementation tasks from the current spec requirements and design. Use this after refining a spec to keep the task list aligned with what needs to be built.

## Usage

```
/spec-tasks
```

No arguments — the command detects available specs and prompts you to select one if multiple exist.

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| _(none)_ | — | Interactive. Selects the spec automatically if only one exists. |

## What It Does

1. **Identifies the spec** — finds specs in `.claude/specs/`. Auto-selects if only one exists.

2. **Reads current spec files** — loads `requirements.md`, `design.md`, and the existing `tasks.md` (if any) to understand what is already planned.

3. **Analyzes changes** — if tasks already exist, compares them against the current requirements and design to find: new requirements not covered by existing tasks, design components without implementation tasks, and tasks that belong to removed or changed requirements.

4. **Generates an updated task list** organized into five phases:
   - **Setup** — scaffolding, dependencies, configuration
   - **Core Implementation** — main feature functionality, data models, business logic
   - **Integration** — API connections, service and UI integration
   - **Testing** — unit, integration, and end-to-end tests
   - **Polish** — error handling, edge cases, documentation

5. **Preserves completed work** — tasks marked as completed are kept unchanged. Pending tasks are updated if requirements changed. Obsolete tasks are marked removed with a note explaining why.

6. **Syncs to the task list** — creates new tasks for new items and updates existing tasks if descriptions changed. Completed tasks are never removed.

7. **Reports changes** — summarizes how many tasks were added, updated, removed, and how many remain pending.

## Example

```
/spec-tasks
```

After running `/spec-refine` to add OAuth support, run `/spec-tasks` to add the new tasks for OAuth implementation without losing your existing completed work.

## Tips

- Always run this after `/spec-refine` to keep tasks aligned with the current spec.
- Review the generated tasks before starting implementation — check that dependencies between tasks make sense.
- Completed tasks are never automatically removed, even if the requirement they trace to has changed.

!!!note
    `/spec-tasks` recalculates task dependencies based on the current task sequence. If you have custom dependency arrangements, review them after regeneration.

## See Also

- [/spec-refine](spec-refine.md) — Update requirements or design before regenerating tasks
- [/spec-sync](spec-sync.md) — Sync task statuses after running implementation scripts
- [/spec-status](spec-status.md) — View current task progress
- [/spec-validate](spec-validate.md) — Validate the spec including task traceability
