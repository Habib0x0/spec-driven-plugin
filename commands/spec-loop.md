---
name: spec-loop
description: Loop spec execution until all tasks are complete
allowed-tools:
  - Bash
  - Read
  - Glob
---

# /spec-loop Command

Run spec-driven implementation in a loop. Each iteration picks the next highest-priority task (using a smart unblock-count heuristic), implements it, and continues until all tasks are done or max iterations reached.

## Usage

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/spec-loop.sh [OPTIONS]
```

## Options

| Flag | Default | Description |
|------|---------|-------------|
| `--spec-name <name>` | auto-detect | Which spec to execute against |
| `--max-iterations <n>` | 50 | Maximum iterations before stopping |
| `--timeout <seconds>` | 1200 (20m) | Per-iteration timeout with stall detection |
| `--skip-e2e` | off | Skip Playwright/browser e2e tests |
| `--batch` | off | Batch same-phase tasks into single sessions |
| `--batch-size <n>` | 3 | Max tasks per batch |
| `--parallel` | off | Run independent tasks in parallel (see /spec-parallel) |
| `--task <T-XX>` | — | Run a specific task then exit |

## What It Does

1. **Smart task selection**: Picks the task that unblocks the most downstream work (not just the next in line)
2. **Pre-computed task brief**: Passes a targeted JSON brief to each session, eliminating cold-start overhead
3. **Timeout + stall detection**: Kills stuck sessions after configurable timeout (default 20min), with heartbeat monitoring every 2min
4. **Per-iteration logging**: Writes to `.claude/specs/<name>/logs/iteration-001.log`, etc.
5. **progress.json**: Machine-readable progress updated after each iteration
6. **learnings.md**: Cross-iteration knowledge carry-forward
7. **Structured events**: Emits JSON `{"event": "iteration_complete", ...}` for parent session parsing
8. **Batch mode**: Groups same-phase independent tasks into single sessions

## Monitoring

### Progress file
```bash
cat .claude/specs/<name>/logs/progress.json
# {"completed": 67, "total": 144, "last_task": "T-67", "last_iteration": 11}
```

### Individual iteration logs
```bash
tail -f .claude/specs/<name>/logs/iteration-012.log
```

### Structured events (grep from output)
```bash
spec-loop.sh ... | grep '"event"'
# {"event": "iteration_complete", "iteration": 1, "task": "T-5", "status": "in_progress", ...}
```

## Prerequisites

- A completed spec in `.claude/specs/<name>/` with all three files
- Run `/spec <name>` first if you haven't created a spec yet
