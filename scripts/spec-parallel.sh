#!/bin/bash
set -e

# ==============================================================================
# spec-parallel.sh — Run independent tasks in parallel via git worktrees
#
# Analyzes the dependency DAG in tasks.md, finds groups of independent tasks,
# and runs them simultaneously in separate git worktrees.
#
# Each worktree gets its own Claude session, and results are merged back
# to the main branch after each group completes.
# ==============================================================================

SPEC_NAME=""
MAX_WORKERS=3
ITERATION_TIMEOUT=1200
SKIP_E2E=false

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/task-parser.sh"

# parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --spec-name)
      SPEC_NAME="$2"
      shift 2
      ;;
    --workers)
      MAX_WORKERS="$2"
      shift 2
      ;;
    --timeout)
      ITERATION_TIMEOUT="$2"
      shift 2
      ;;
    --skip-e2e)
      SKIP_E2E=true
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: spec-parallel.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --spec-name <name>       Spec to execute (auto-detected if only one)"
      echo "  --workers <n>            Max parallel workers (default: 3)"
      echo "  --timeout <seconds>      Per-task timeout (default: 1200 = 20min)"
      echo "  --skip-e2e               Skip Playwright/e2e verification"
      exit 1
      ;;
  esac
done

# auto-detect spec
if [ -z "$SPEC_NAME" ]; then
  if [ ! -d ".claude/specs" ]; then
    echo "Error: No .claude/specs directory found."
    exit 1
  fi
  SPECS=($(ls -d .claude/specs/*/  2>/dev/null | xargs -I{} basename {}))
  if [ ${#SPECS[@]} -eq 0 ]; then
    echo "Error: No specs found."
    exit 1
  elif [ ${#SPECS[@]} -eq 1 ]; then
    SPEC_NAME="${SPECS[0]}"
  else
    echo "Error: Multiple specs. Use --spec-name."
    exit 1
  fi
fi

SPEC_DIR=".claude/specs/$SPEC_NAME"
WORKTREE_BASE="/tmp/spec-worktrees-$$"
MAIN_BRANCH=$(git branch --show-current)

mkdir -p "$WORKTREE_BASE"

cleanup_worktrees() {
  echo ""
  echo "Cleaning up worktrees..."
  for wt in "$WORKTREE_BASE"/worker-*; do
    [ -d "$wt" ] || continue
    local wt_name=$(basename "$wt")
    git worktree remove --force "$wt" 2>/dev/null || true
    git branch -D "spec-parallel-$wt_name" 2>/dev/null || true
  done
  rm -rf "$WORKTREE_BASE"
}
trap cleanup_worktrees EXIT

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  SPEC PARALLEL: $SPEC_NAME"
echo "║  Workers: $MAX_WORKERS | Timeout: ${ITERATION_TIMEOUT}s"
echo "║  Branch: $MAIN_BRANCH"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Find parallel groups
GROUPS=$(get_parallel_groups "$SPEC_DIR/tasks.md")
GROUP_COUNT=$(echo "$GROUPS" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")

echo "Found $GROUP_COUNT parallel task groups:"
echo "$GROUPS" | python3 -c "
import json, sys
groups = json.load(sys.stdin)
for i, g in enumerate(groups):
    print(f'  Group {i+1}: {', '.join(g)}')
"
echo ""

# Process each group
GROUP_IDX=0
echo "$GROUPS" | python3 -c "import json,sys; [print(' '.join(g)) for g in json.load(sys.stdin)]" | while read -r GROUP_TASKS; do
  GROUP_IDX=$((GROUP_IDX + 1))
  TASK_ARRAY=($GROUP_TASKS)
  TASK_COUNT=${#TASK_ARRAY[@]}
  
  # Limit to MAX_WORKERS
  if [ "$TASK_COUNT" -gt "$MAX_WORKERS" ]; then
    TASK_COUNT=$MAX_WORKERS
  fi
  
  echo "═══════════════════════════════════════════════════════════════"
  echo "  Group $GROUP_IDX: ${TASK_ARRAY[*]:0:$TASK_COUNT}"
  echo "═══════════════════════════════════════════════════════════════"
  
  if [ "$TASK_COUNT" -eq 1 ]; then
    # Single task — just run it directly (no worktree needed)
    echo "  Single task, running directly..."
    SKIP_FLAG=""
    if [ "$SKIP_E2E" = true ]; then
      SKIP_FLAG="--skip-e2e"
    fi
    "$SCRIPT_DIR/spec-exec.sh" --spec-name "$SPEC_NAME" --task "${TASK_ARRAY[0]}" --timeout "$ITERATION_TIMEOUT" $SKIP_FLAG
    continue
  fi
  
  # Multiple tasks — run in parallel worktrees
  PIDS=()
  WORKER_DIRS=()
  
  for i in $(seq 0 $((TASK_COUNT - 1))); do
    TASK="${TASK_ARRAY[$i]}"
    WORKER_NAME="worker-$TASK"
    WORKER_DIR="$WORKTREE_BASE/$WORKER_NAME"
    WORKER_BRANCH="spec-parallel-$WORKER_NAME"
    
    echo "  Starting worker for $TASK in $WORKER_DIR"
    
    # Create worktree branch from current state
    git branch -D "$WORKER_BRANCH" 2>/dev/null || true
    git worktree add -b "$WORKER_BRANCH" "$WORKER_DIR" HEAD 2>/dev/null
    
    # Run spec-exec in the worktree
    (
      cd "$WORKER_DIR"
      SKIP_FLAG=""
      if [ "$SKIP_E2E" = true ]; then
        SKIP_FLAG="--skip-e2e"
      fi
      "$SCRIPT_DIR/spec-exec.sh" --spec-name "$SPEC_NAME" --task "$TASK" --timeout "$ITERATION_TIMEOUT" $SKIP_FLAG \
        > "$WORKTREE_BASE/$WORKER_NAME.log" 2>&1
    ) &
    PIDS+=($!)
    WORKER_DIRS+=("$WORKER_DIR")
  done
  
  # Wait for all workers
  echo "  Waiting for ${#PIDS[@]} workers..."
  FAILED=0
  for i in "${!PIDS[@]}"; do
    wait "${PIDS[$i]}" || {
      echo "  ⚠️  Worker for ${TASK_ARRAY[$i]} exited with error"
      FAILED=$((FAILED + 1))
    }
  done
  
  echo "  All workers complete ($FAILED failures)"
  
  # Merge results back to main branch
  echo "  Merging results..."
  for i in $(seq 0 $((TASK_COUNT - 1))); do
    TASK="${TASK_ARRAY[$i]}"
    WORKER_BRANCH="spec-parallel-worker-$TASK"
    
    if git merge --no-edit "$WORKER_BRANCH" 2>/dev/null; then
      echo "    ✅ Merged $TASK"
    else
      echo "    ⚠️  Merge conflict for $TASK — resolve manually"
      git merge --abort 2>/dev/null || true
    fi
    
    # Clean up worktree
    git worktree remove --force "$WORKTREE_BASE/worker-$TASK" 2>/dev/null || true
    git branch -D "$WORKER_BRANCH" 2>/dev/null || true
  done
  
  echo ""
done

echo ""
echo "✅ Parallel execution complete."

# Final status
STATUSES=$(count_task_statuses "$SPEC_DIR/tasks.md")
echo ""
echo "$(echo "$STATUSES" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'Verified: {d[\"verified\"]}/{d[\"total\"]} | Completed: {d[\"completed\"]} | Pending: {d[\"pending\"]} | Blocked: {d[\"blocked\"]}')")"
