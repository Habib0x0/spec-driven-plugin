---
name: spec-loop
description: Loop spec execution until all tasks are complete
allowed-tools:
  - Bash
  - Read
  - Glob
---

# /spec-loop Command

Run spec-driven implementation in a loop. Each iteration picks the next highest-priority task, implements it, and continues until all tasks are done or max iterations reached.

## Usage

Run the script directly from your project root:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/spec-loop.sh [--spec-name <name>] [--max-iterations <n>] [--progress-tail <n>] [--no-complete]
```

Or via Bash tool if invoked within Claude Code:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/spec-loop.sh --spec-name <name>
```

## Arguments

- `--spec-name <name>` - Which spec to execute against. Auto-detected if only one spec exists in `.claude/specs/`.
- `--max-iterations <n>` - Maximum number of iterations before stopping. Default: 50.
- `--progress-tail <n>` - Number of recent progress entries to include in prompt. Default: 20.
- `--no-complete` - Skip auto-triggering the post-completion pipeline when all tasks are done.

## What It Does

1. Reads your spec files fresh each iteration
2. Runs Claude to implement one feature per iteration
3. Runs verification gates on completed tasks
4. Checks output for `<promise>COMPLETE</promise>` to detect completion
5. Automatically runs the post-completion pipeline (UAT, docs, release, retro) on completion
6. Stops when all tasks are done or max iterations reached

## Prerequisites

- A completed spec in `.claude/specs/<name>/` with all three files
- Run `/spec <name>` first if you haven't created a spec yet
