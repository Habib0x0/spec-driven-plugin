---
name: spec-exec
description: Execute one spec task by running Claude in autonomous mode
allowed-tools:
  - Bash
  - Read
  - Glob
---

# /spec-exec Command

Run a single iteration of spec-driven implementation. Uses smart task selection to pick the highest-impact task, passes a pre-computed task brief, and runs with timeout protection.

## Usage

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/spec-exec.sh [OPTIONS]
```

## Options

| Flag | Default | Description |
|------|---------|-------------|
| `--spec-name <name>` | auto-detect | Which spec to execute against |
| `--timeout <seconds>` | 1200 (20m) | Execution timeout |
| `--skip-e2e` | off | Skip Playwright/browser e2e tests |
| `--task <T-XX>` | smart selection | Run a specific task ID |

## What It Does

1. **Smart task selection**: Picks the task that unblocks the most downstream work
2. **Pre-computed task brief**: Passes targeted JSON brief to eliminate cold-start overhead
3. **Timeout protection**: Kills stuck sessions after configurable timeout
4. **learnings.md**: Reads and appends cross-iteration knowledge
5. **Per-execution log**: Writes to `.claude/specs/<name>/logs/exec-<timestamp>.log`
6. **Structured events**: Emits JSON completion signal for parsing

## Prerequisites

- A completed spec in `.claude/specs/<name>/` with all three files
- Run `/spec <name>` first if you haven't created a spec yet
