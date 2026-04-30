# /spec-exec

Run a single iteration of autonomous spec implementation. Claude picks the highest-priority pending task, implements it, tests it, updates the spec, and commits — then stops.

## Usage

Run the script from your project root:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/spec-exec.sh [--spec-name <name>]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--spec-name <name>` | No | Which spec to execute against. Auto-detected if only one spec exists in `.claude/specs/`. |

## What It Does

1. Reads your spec files (`requirements.md`, `design.md`, `tasks.md`).
2. Builds a prompt with the full spec context.
3. Runs Claude in autonomous mode with that prompt.
4. Claude selects the next highest-priority pending task, implements it, writes tests, updates `tasks.md`, and commits the changes.
5. Stops after one task.

## Prerequisites

- A completed spec in `.claude/specs/<name>/` with all three files (`requirements.md`, `design.md`, `tasks.md`).
- Run `/spec <name>` first if you have not created a spec yet.

## Example

```bash
bash scripts/spec-exec.sh --spec-name user-authentication
```

## Tips

- Use `/spec-exec` when you want to review each task's implementation before proceeding to the next. It gives you a checkpoint after every task.
- Use `/spec-loop` instead if you want to run all tasks unattended.
- After each run, check `/spec-status` to see what was completed and what is next.

## See Also

- [/spec-loop](spec-loop.md) — Run all tasks in a loop until complete
- [/spec-status](spec-status.md) — Check progress after implementation
- [/spec-accept](spec-accept.md) — Run acceptance testing once all tasks are complete
