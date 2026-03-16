---
name: spec-parallel
description: Run independent spec tasks in parallel via git worktrees
allowed-tools:
  - Bash
  - Read
  - Glob
---

# /spec-parallel Command

Run independent tasks from the spec simultaneously in separate git worktrees. Analyzes the dependency DAG to find tasks that can safely execute in parallel.

## Usage

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/spec-parallel.sh [OPTIONS]
```

## Options

- `--spec-name <name>` — Spec to execute (auto-detected if only one exists)
- `--workers <n>` — Maximum parallel workers (default: 3)
- `--timeout <seconds>` — Per-task timeout (default: 1200 = 20min)
- `--skip-e2e` — Skip Playwright/browser e2e tests (for Docker/deployed environments)

## What It Does

1. Parses `tasks.md` and builds a dependency DAG
2. Groups tasks into parallelizable sets (no mutual dependencies)
3. For each group:
   - Creates git worktrees for parallel execution
   - Runs `spec-exec.sh --task <T-XX>` in each worktree
   - Waits for all workers to complete
   - Merges results back to the main branch
4. Reports merge conflicts for manual resolution if needed

## When to Use

- When you have many independent tasks (e.g., unit test tasks for different modules)
- When tasks in different phases don't depend on each other
- When you want 2-3x throughput on a large spec

## Prerequisites

- A completed spec in `.claude/specs/<name>/` with all three files
- Git repository with clean working tree
- `claude` CLI installed
