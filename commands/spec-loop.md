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
${CLAUDE_PLUGIN_ROOT}/scripts/spec-loop.sh [--spec-name <name>] [--max-iterations <n>]
```

Or via Bash tool if invoked within Claude Code:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/spec-loop.sh --spec-name <name>
```

## Arguments

- `--spec-name <name>` - Which spec to execute against. Auto-detected if only one spec exists in `.claude/specs/`.
- `--max-iterations <n>` - Maximum number of iterations before stopping. Default: 50.

## What It Does

1. Reads your spec files fresh each iteration
2. Runs Claude to implement one feature per iteration
3. Checks output for `<promise>COMPLETE</promise>` to detect completion
4. Stops when all tasks are done or max iterations reached
5. Ctrl+C to cancel at any time

## Prerequisites

- A completed spec in `.claude/specs/<name>/` with all three files
- Run `/spec <name>` first if you haven't created a spec yet
