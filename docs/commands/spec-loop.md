# /spec-loop

Run spec-driven implementation in a continuous loop. Each iteration implements one pending task, then automatically continues to the next until all tasks are complete or the iteration limit is reached.

## Usage

Run the script from your project root:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/spec-loop.sh [--spec-name <name>] [--max-iterations <n>] [--progress-tail <n>]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--spec-name <name>` | No | Which spec to execute against. Auto-detected if only one spec exists in `.claude/specs/`. |
| `--max-iterations <n>` | No | Maximum number of iterations before stopping. Default: 50. |
| `--progress-tail <n>` | No | Number of recent progress entries included in each iteration's prompt. Default: 20. |

## What It Does

1. Reads your spec files fresh at the start of each iteration.
2. Runs Claude to implement one task per iteration.
3. Detects completion via a signal in Claude's output.
4. Stops automatically when all tasks are done, the max iteration count is reached, or you press Ctrl+C.

Each iteration picks the highest-priority pending task, implements it, updates `tasks.md`, and commits. The next iteration starts from the updated state.

After the loop finishes, run `/spec-sync` to bring the Claude Code task list up to date.

## Prerequisites

- A completed spec in `.claude/specs/<name>/` with all three files.
- Run `/spec <name>` first if you have not created a spec yet.

## Example

```bash
# Run with defaults (auto-detect spec, up to 50 iterations)
${CLAUDE_PLUGIN_ROOT}/scripts/spec-loop.sh

# Run a specific spec with a conservative limit
${CLAUDE_PLUGIN_ROOT}/scripts/spec-loop.sh --spec-name payment-flow --max-iterations 20
```

## Tips

- Use `/spec-loop` for straightforward features where you trust the implementation to proceed without per-task review.
- Use `/spec-exec` instead if you want to inspect each task's output before moving on.
- Use `/spec-team` instead if the feature is security-sensitive or complex enough to warrant review gates.
- Press Ctrl+C at any time to pause the loop. The current task's work is preserved. Resume by running the loop again.
- Setting a `--max-iterations` limit prevents runaway loops on large or ambiguous specs.

!!!warning
    The loop runs autonomously. Review the commits afterward with `git log` to verify the implementation matches your expectations.

## See Also

- [/spec-exec](spec-exec.md) — Single-task implementation with manual checkpoints
- [/spec-team](spec-team.md) — Loop with multi-agent review and testing gates
- [/spec-sync](spec-sync.md) — Sync task statuses after the loop completes
- [/spec-status](spec-status.md) — Check progress during or after the loop
