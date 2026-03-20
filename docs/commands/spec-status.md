# /spec-status

Display the current progress of a spec: how many tasks are complete, what is in progress, what is blocked, and whether cross-spec dependencies are satisfied.

## Usage

```
/spec-status
```

No arguments — the command detects available specs. If multiple exist, it shows a summary for all or asks which one to detail.

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| _(none)_ | — | Interactive. Auto-selects the spec if only one exists. |

## What It Does

1. **Reads spec files** — counts user stories in `requirements.md`, verifies `design.md` exists, and parses `tasks.md` for task counts and statuses.

2. **Calculates progress** — tracks tasks across five states: Pending, In Progress, Completed, Wired, and Verified. A task is only considered truly done when it is completed, wired into the application, and verified with tests.

3. **Checks task list sync** — compares `tasks.md` with the Claude Code task list to identify tasks that are out of sync or orphaned.

4. **Checks cross-spec dependencies** — if the spec declares dependencies on other specs (via a `## Depends On` section in `requirements.md`), reports whether those specs are fully verified. Incomplete dependencies block execution commands.

5. **Reports integration health** — highlights tasks that are completed but not yet wired into the application, and tasks that are wired but not yet verified. These are common sources of features that appear done but do not actually work.

6. **Recommends next actions** — suggests which task to start next, which blocked tasks need prerequisites completed, and when the spec is ready for validation or release.

## Example Output

```
## Spec Status: user-authentication

### Progress
| Status           | Count | Percentage |
|------------------|-------|------------|
| Verified (done)  | 4     | 40%        |
| Wired (not verified) | 1 | 10%       |
| In Progress      | 1     | 10%        |
| Pending          | 4     | 40%        |

[████████░░░░░░░░] 40% verified

### Integration Health
- Tasks completed but NOT wired: 1 (these need wiring!)
```

## Tips

- Run periodically during implementation to stay oriented.
- Pay close attention to "Unwired Tasks" — a task marked completed but not wired is the most common reason a feature appears done but does not work for users.
- A task marked completed but not wired or verified does not count toward the spec's true progress percentage.
- If a cross-spec dependency is incomplete, execution commands (`/spec-exec`, `/spec-loop`, `/spec-team`) will refuse to run until it is resolved.

!!!warning
    "Completed" does not mean done. A task is only finished when it is completed, wired, and verified. The status report makes this distinction explicit.

## See Also

- [/spec-sync](spec-sync.md) — Sync task statuses after running implementation scripts
- [/spec-validate](spec-validate.md) — Run a full consistency check on the spec
- [/spec-exec](spec-exec.md) — Implement the next pending task
