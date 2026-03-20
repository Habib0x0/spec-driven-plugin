# Execution

After requirements, design, and tasks are complete, execution scripts implement the spec autonomously. Three modes are available depending on how much oversight you want.

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
spec-loop.sh --spec-name user-authentication --max-iterations 20
```

Runs iterations in a loop until all tasks are verified or the maximum iteration count is reached. The loop detects completion when Claude outputs `<promise>COMPLETE</promise>` in its response.

Options:

| Flag | Default | Description |
|------|---------|-------------|
| `--spec-name` | auto-detected | Spec to run (required if multiple specs exist) |
| `--max-iterations` | 50 | Maximum iterations before stopping |
| `--progress-tail` | 20 | Number of progress entries included in each prompt |
| `--no-worktree` | off | Commit directly to current branch instead of a worktree |

**Prompt optimization for long runs:** The loop script optimizes prompts to prevent token bloat over many iterations. On the first iteration, the full requirements and design are included. On subsequent iterations, they are referenced by file path and only loaded on demand. The progress log is trimmed to the last N entries (configurable via `--progress-tail`).

## Mode 3: Agent team (spec-team.sh)

```bash
spec-team.sh --spec-name user-authentication
```

Runs implementation with four specialized agents per task:

```
Implementer writes code
      |
Tester verifies (Playwright / test suite)
      |
  PASS -> Reviewer checks quality and security (Opus)
               |
           APPROVE -> commit
           REJECT  -> Debugger fixes -> back to Tester
  FAIL -> Debugger fixes -> back to Tester
```

Agent team mode costs approximately 3-4x more tokens than single-agent mode because each agent maintains its own context window. Use it when:

- Tasks were being marked complete without real testing in loop mode
- The feature is security-sensitive and requires a code review before each commit
- You want strict separation between the agent that writes code and the agent that tests it

!!!note
    Agent team mode requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, which the script sets automatically. It also requires the Playwright MCP for UI testing.

## Git worktree isolation

By default, all execution scripts create a git worktree for the spec:

- **Branch:** `spec/<spec-name>`
- **Path:** `.claude/specs/.worktrees/<spec-name>/`

The main branch stays clean while the spec is being implemented. Multiple specs can run in parallel on separate worktrees.

When all tasks are complete, the script prints a suggested PR command:

```bash
gh pr create --head spec/user-authentication --title "user-authentication"
```

Use `--no-worktree` to commit directly to the current branch instead.

See [Worktrees](../advanced/worktrees.md) for more detail.

## Crash recovery

`spec-loop.sh` and `spec-team.sh` create checkpoint commits before each iteration. If Claude exits with a non-zero exit code, the branch is automatically rolled back to the last checkpoint.

See [Crash recovery](../advanced/crash-recovery.md) for how checkpoints work.

## Progress log

The loop creates a `progress.md` file in the spec directory. It is append-only — each iteration adds a new entry separated by `---`. Never edit previous entries.

If Claude fails to update `progress.md` during an iteration, the script appends a fallback entry automatically.

## Task sync

After the loop completes, run `/spec-sync` to update the Claude Code task list from `tasks.md`. The subprocess cannot call `TaskUpdate` directly, so this reconciliation step keeps the two in sync.

## Cross-spec dependencies

Before creating a worktree or running any iteration, execution scripts check that all declared dependencies are met. A dependency is satisfied when all its tasks have `Status: completed`, `Wired: yes/n/a`, and `Verified: yes`.

If a dependency is not satisfied, the script exits with an error rather than starting the run. See [Cross-spec dependencies](../advanced/cross-spec-deps.md).
