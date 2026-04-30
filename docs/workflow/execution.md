# Execution

After requirements, design, and tasks are complete, execution scripts implement the spec autonomously. Two modes are available depending on how much oversight you want.

## Mode 1: Single iteration (spec-exec)

```
/spec-exec
```

Runs one implementation cycle:

1. Picks the highest-priority pending task
2. Implements the code
3. Wires the code into the application
4. Tests and verifies
5. Updates `tasks.md` (Status, Wired, Verified fields)
6. Commits

Use this when you want to review each task manually before proceeding to the next.

## Mode 2: Automated loop (spec-loop.sh)

```bash
bash scripts/spec-loop.sh --spec-name user-authentication --max-iterations 20
```

Runs iterations in a loop until all tasks are verified or the maximum iteration count is reached. The loop detects completion when Claude outputs `<promise>COMPLETE</promise>` in its response.

Options:

| Flag | Default | Description |
|------|---------|-------------|
| `--spec-name` | auto-detected | Spec to run (required if multiple specs exist) |
| `--max-iterations` | 50 | Maximum iterations before stopping |
| `--progress-tail` | 20 | Number of progress entries included in each prompt |
| `--on-complete` | (none) | Shell command to run when the loop finishes successfully |

**Prompt optimization for long runs:** The loop script optimizes prompts to prevent token bloat over many iterations. On the first iteration, the full requirements and design are included. On subsequent iterations, they are referenced by file path and only loaded on demand. The progress log is trimmed to the last N entries (configurable via `--progress-tail`).

## Crash recovery

`spec-loop.sh` creates checkpoint commits before each iteration. If Claude exits with a non-zero exit code, the branch is automatically rolled back to the last checkpoint.

## Progress log

The loop creates a `progress.md` file in the spec directory. It is append-only — each iteration adds a new entry separated by `---`. Never edit previous entries.

If Claude fails to update `progress.md` during an iteration, the script appends a fallback entry automatically.

## Cross-spec dependencies

Before running any iteration, execution scripts check that all declared dependencies are met. A dependency is satisfied when all its tasks have `Status: completed`, `Wired: yes/n/a`, and `Verified: yes`.

If a dependency is not satisfied, the script exits with an error rather than starting the run. See [Cross-spec dependencies](../advanced/cross-spec-deps.md).

## Post-completion pipeline

After the loop finishes, run the post-completion scripts manually or pass `--on-complete`:

```bash
# run post-completion pipeline manually
bash scripts/spec-complete.sh --spec-name user-authentication

# or trigger it automatically when the loop finishes
bash scripts/spec-loop.sh \
  --spec-name user-authentication \
  --on-complete "bash scripts/spec-complete.sh --spec-name user-authentication"
```

`spec-complete.sh` runs: accept → docs → release → retro. It halts early if UAT rejects the spec. Individual steps can be skipped with `--skip-accept`, `--skip-docs`, `--skip-release`, or `--skip-retro`.
