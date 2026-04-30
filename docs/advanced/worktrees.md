# Git worktrees

Git worktree isolation for spec execution is **not currently implemented**. The execution scripts (`spec-exec.sh`, `spec-loop.sh`) commit directly to the current branch.

## Current behavior

Both scripts:
- Work in the current git repository
- Commit changes directly to the active branch
- `spec-loop.sh` uses checkpoint commits for crash recovery

## Recommended workflow

If you want branch isolation while running a spec loop, create the branch manually before starting:

```bash
git checkout -b spec/user-authentication
bash scripts/spec-loop.sh --spec-name user-authentication
```

When done, open a PR from that branch:

```bash
gh pr create --head spec/user-authentication --title "user-authentication"
```

## Checkpoint recovery

`spec-loop.sh` does implement checkpoint-based crash recovery. Before each iteration, it commits a checkpoint. If the agent crashes or exits with a non-zero code, the branch rolls back to the last checkpoint automatically.

See [Crash recovery](crash-recovery.md) for details.
