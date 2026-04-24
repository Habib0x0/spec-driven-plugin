#!/usr/bin/env bash
# lib/checkpoint.sh — Checkpoint commit creation and rollback for crash recovery
# Provides create_checkpoint() and handle_checkpoint_recovery() for loop-based execution scripts.
# Source this file; do not execute directly.

# create_checkpoint(iteration, work_dir)
# Stages all changes and creates a checkpoint commit before an iteration.
# Sets CHECKPOINT_SHA to the commit hash, or empty string if no changes existed.
create_checkpoint() {
  local iteration="$1"
  local work_dir="$2"

  CHECKPOINT_SHA=""

  # check for uncommitted changes (staged or unstaged)
  if [[ -z "$(git -C "$work_dir" status --porcelain)" ]]; then
    return 0
  fi

  # stage everything and commit
  git -C "$work_dir" add -A
  if git -C "$work_dir" commit -m "checkpoint: pre-iteration $iteration" >/dev/null 2>&1; then
    CHECKPOINT_SHA="$(git -C "$work_dir" rev-parse HEAD)"
    echo "Created checkpoint: pre-iteration $iteration ($CHECKPOINT_SHA)"
  else
    echo "Warning: checkpoint commit failed for iteration $iteration, continuing without checkpoint" >&2
  fi
}

# handle_checkpoint_recovery(exit_code, checkpoint_sha, iteration, work_dir)
# Rolls back to checkpoint if the agent exited non-zero and a checkpoint exists.
handle_checkpoint_recovery() {
  local exit_code="$1"
  local checkpoint_sha="$2"
  local iteration="$3"
  local work_dir="$4"

  # nothing to do if the agent succeeded or no checkpoint was created
  if [[ "$exit_code" -eq 0 ]] || [[ -z "$checkpoint_sha" ]]; then
    return 0
  fi

  # non-zero exit with a checkpoint — roll back
  if git -C "$work_dir" reset --hard "$checkpoint_sha" >/dev/null 2>&1; then
    echo "Rolled back to checkpoint: pre-iteration $iteration" >&2
  else
    echo "CRITICAL: git reset --hard failed. Manually inspect branch in: $work_dir" >&2
  fi
}
