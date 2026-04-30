# Crash recovery

`spec-loop.sh` implements crash recovery via checkpoint commits. If Claude exits with a non-zero exit code during an iteration, the branch is automatically rolled back to the state before that iteration started.

## How checkpoints work

At the start of each iteration, before Claude is invoked, the script calls `create_checkpoint()` from `scripts/lib/checkpoint.sh`:

1. Check for uncommitted changes (staged or unstaged) in the working directory
2. If changes exist, stage everything and create a commit: `checkpoint: pre-iteration N`
3. Record the commit hash as `CHECKPOINT_SHA`

If there are no uncommitted changes (the previous iteration committed cleanly), no checkpoint commit is created and `CHECKPOINT_SHA` is empty.

## Rollback behavior

After Claude exits, the script checks the exit code:

- **Exit code 0** — success, no rollback needed
- **Non-zero exit code with a checkpoint** — call `git reset --hard <CHECKPOINT_SHA>` to discard the failed iteration's partial work and return to the pre-iteration state
- **Non-zero exit code without a checkpoint** — nothing to roll back, continue

If `git reset --hard` itself fails (rare), the script prints a critical warning with the current git state so you can inspect manually.

## What triggers a non-zero exit

Claude exits non-zero when it encounters an unrecoverable error: tool failures, network issues, hitting context limits, or explicit errors. Rollback ensures these situations leave the codebase in a clean state rather than with half-written code.

## Checkpoint commits in git history

Checkpoint commits appear in git history with the message `checkpoint: pre-iteration N`. They are real commits on the spec branch. When you open a PR, you may want to squash or rebase these out:

```bash
git rebase -i main
```

## Manual recovery

If you need to recover manually, checkpoint commits are labeled and easy to find:

```bash
git log --oneline | grep checkpoint
```

Roll back to a specific checkpoint:

```bash
git reset --hard <checkpoint-sha>
```
