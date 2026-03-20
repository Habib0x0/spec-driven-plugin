# Worktree isolation

By default, execution scripts create a git worktree for each spec so that implementation work is isolated from the main branch.

## How it works

When `spec-loop.sh`, `spec-exec.sh`, or `spec-team.sh` starts, it calls `setup_worktree()` from `scripts/lib/worktree.sh`. This function:

1. Creates (or reuses) a worktree at `.claude/specs/.worktrees/<spec-name>/`
2. Creates (or reuses) a branch named `spec/<spec-name>`
3. Sets the working directory for the session to the worktree path

If the worktree directory exists but is not a valid worktree (stale path), it is cleaned up and recreated.

The `.claude/specs/.worktrees/` directory is added to `.gitignore` automatically so worktree paths are not tracked.

## Branch naming

Each spec gets its own branch:

```
spec/user-authentication
spec/dashboard-redesign
spec/payment-integration
```

This means multiple specs can be implemented in parallel without conflicting with each other or with the main branch.

## Reusing an existing worktree

If you run the same spec-loop again after stopping, the script reuses the existing worktree and branch. Work continues from where it left off. Progress entries from the previous session are in `progress.md`.

## PR workflow

When all tasks are complete, the execution script prints a suggested PR command:

```bash
gh pr create --head spec/user-authentication --title "user-authentication"
```

Run this from your project root to open a pull request from the spec branch into your main branch.

## Disabling worktrees

Use `--no-worktree` to commit directly to the current branch:

```bash
spec-loop.sh --spec-name user-authentication --no-worktree
```

This matches the behavior from v2.x of the plugin. Useful when:
- You are working in a repository that does not support git worktrees
- You want all commits on the current branch without a PR step
- You are running in a CI environment where worktree management is not needed

!!!warning
    Without worktrees, implementation commits go directly to your current branch. Make sure you are on the correct branch before running without `--no-worktree`.
