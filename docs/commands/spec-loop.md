# /spec-loop

Run spec-driven implementation in a continuous loop. Each iteration implements one pending task, then automatically continues to the next until all tasks are complete or the iteration limit is reached.

## Usage

Run the script from your project root:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/spec-loop.sh [--spec-name <name>] [--max-iterations <n>] [--progress-tail <n>] [--on-complete <command>]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--spec-name <name>` | No | Which spec to execute against. Auto-detected if only one spec exists in `.claude/specs/`. |
| `--max-iterations <n>` | No | Maximum number of iterations before stopping. Default: 50. |
| `--progress-tail <n>` | No | Number of recent progress entries included in each iteration's prompt. Default: 20. |
| `--on-complete <cmd>` | No | Shell command to run when the loop finishes successfully (all tasks verified). |

## What It Does

1. Reads your spec files fresh at the start of each iteration.
2. Runs Claude to implement one task per iteration.
3. Detects completion via `<promise>COMPLETE</promise>` in Claude's output.
4. Stops automatically when all tasks are done, the max iteration count is reached, or you press Ctrl+C.

Each iteration picks the highest-priority pending task, implements it, updates `tasks.md`, and commits. The next iteration starts from the updated state.

## Prerequisites

- A completed spec in `.claude/specs/<name>/` with all three files.
- Run `/spec <name>` first if you have not created a spec yet.

## Example

```bash
# Run with defaults (auto-detect spec, up to 50 iterations)
bash scripts/spec-loop.sh

# Run a specific spec with a conservative limit
bash scripts/spec-loop.sh --spec-name payment-flow --max-iterations 20

# Run post-completion pipeline automatically when done
bash scripts/spec-loop.sh \
  --spec-name payment-flow \
  --on-complete "bash scripts/spec-complete.sh --spec-name payment-flow"
```

## Tips

- Use `/spec-loop` for straightforward features where you trust the implementation to proceed without per-task review.
- Use `/spec-exec` instead if you want to inspect each task's output before moving on.
- Press Ctrl+C at any time to pause the loop. The current task's work is preserved. Resume by running the loop again.
- Setting a `--max-iterations` limit prevents runaway loops on large or ambiguous specs.

!!!warning
    The loop runs autonomously. Review the commits afterward with `git log` to verify the implementation matches your expectations.

## See Also

- [/spec-exec](spec-exec.md) — Single-task implementation with manual checkpoints
- [/spec-status](spec-status.md) — Check progress during or after the loop
- [/spec-accept](spec-accept.md) — Run acceptance testing after the loop completes
