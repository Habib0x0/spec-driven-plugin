#!/usr/bin/env bash
# lib/parallel.sh — Parallel task execution utilities for spec-loop
# Provides dependency graph parsing, batch scheduling, parallel launch, and merge consolidation.
# Source this file; do not execute directly.

PARALLEL_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# parse_dependency_graph(tasks_file)
# Reads tasks.md and outputs one line per task:
#   task_id:dep1,dep2,...
# Tasks with no dependencies output: task_id:none
parse_dependency_graph() {
  local tasks_file="$1"

  if [ ! -f "$tasks_file" ]; then
    echo "Error: tasks file not found: $tasks_file" >&2
    return 1
  fi

  local current_task=""
  while IFS= read -r line; do
    # match task headers like "### T-1: ..."
    if [[ "$line" =~ ^###\ (T-[0-9]+(\.[0-9]+)?): ]]; then
      current_task="${BASH_REMATCH[1]}"
    fi

    # match dependency lines like "- **Dependencies**: T-1, T-2" or "- **Dependencies**: none"
    if [[ -n "$current_task" && "$line" =~ ^-\ \*\*Dependencies\*\*:\ (.+)$ ]]; then
      local deps="${BASH_REMATCH[1]}"
      deps=$(echo "$deps" | sed 's/ //g')
      echo "$current_task:$deps"
      current_task=""
    fi
  done < "$tasks_file"
}

# _get_task_status(tasks_file, task_id)
# Looks up the status of a single task by reading tasks.md.
# Compatible with bash 3.x (no associative arrays).
_get_task_status() {
  local tasks_file="$1"
  local target_id="$2"

  local in_task=false
  while IFS= read -r line; do
    if [[ "$line" =~ ^###\ ${target_id}: ]]; then
      in_task=true
    elif [[ "$line" =~ ^###\  ]]; then
      in_task=false
    fi
    if $in_task && [[ "$line" =~ ^-\ \*\*Status\*\*:\ (.+)$ ]]; then
      echo "${BASH_REMATCH[1]}"
      return
    fi
  done < "$tasks_file"

  echo "unknown"
}

# get_ready_tasks(tasks_file)
# Returns task IDs whose status is "pending" and all dependencies are "completed".
# Output: space-separated task IDs on a single line.
get_ready_tasks() {
  local tasks_file="$1"

  if [ ! -f "$tasks_file" ]; then
    echo "Error: tasks file not found: $tasks_file" >&2
    return 1
  fi

  # parse dependency graph
  local graph_output
  graph_output=$(parse_dependency_graph "$tasks_file")

  local ready_tasks=""
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    local task_id="${line%%:*}"
    local deps="${line#*:}"

    # skip non-pending tasks
    local task_status
    task_status=$(_get_task_status "$tasks_file" "$task_id")
    if [[ "$task_status" != "pending" ]]; then
      continue
    fi

    # check if all deps are completed
    local all_deps_met=true
    if [[ "$deps" != "none" ]]; then
      local old_ifs="$IFS"
      IFS=','
      for dep in $deps; do
        local dep_status
        dep_status=$(_get_task_status "$tasks_file" "$dep")
        if [[ "$dep_status" != "completed" ]]; then
          all_deps_met=false
          break
        fi
      done
      IFS="$old_ifs"
    fi

    if $all_deps_met; then
      ready_tasks="$ready_tasks $task_id"
    fi
  done <<< "$graph_output"

  echo "$ready_tasks" | xargs
}

# launch_parallel_task(task_id, spec_dir, work_dir, log_dir, iteration)
# Creates a per-task git worktree, builds a task-specific prompt,
# launches claude in the background, and returns the PID.
launch_parallel_task() {
  local task_id="$1"
  local spec_dir="$2"
  local work_dir="$3"
  local log_dir="$4"
  local iteration="$5"

  # source worktree.sh for per-task worktree creation
  if ! type _create_worktree &>/dev/null; then
    source "$PARALLEL_SH_DIR/worktree.sh"
  fi

  local spec_name
  spec_name=$(basename "$spec_dir")

  # create a per-task worktree branch
  local task_slug
  task_slug=$(echo "$task_id" | tr '[:upper:]' '[:lower:]')
  local branch_name="spec/${spec_name}-${task_slug}"
  local worktree_base=".claude/specs/.worktrees"
  local worktree_path="$worktree_base/${spec_name}-${task_slug}"

  mkdir -p "$worktree_base"

  # clean up stale worktree if it exists
  if [ -d "$worktree_path" ]; then
    git worktree remove "$worktree_path" --force 2>/dev/null || true
    git worktree prune 2>/dev/null
  fi

  _create_worktree "$worktree_path" "$branch_name"

  local task_worktree
  task_worktree="$(cd "$worktree_path" && pwd)"

  # extract task description from tasks.md
  # uses awk to grab from the task header to the next task header (exclusive)
  local task_section
  task_section=$(awk "/^### ${task_id}:/{found=1} found && /^### T-/ && !/^### ${task_id}:/{exit} found" "$spec_dir/tasks.md")
  if [ -z "$task_section" ]; then
    task_section=$(awk "/^### ${task_id}:/,0" "$spec_dir/tasks.md")
  fi

  # build the implementer prompt
  local log_file="$log_dir/iteration-${iteration}-task-${task_id}.log"
  mkdir -p "$log_dir"

  local prompt
  prompt=$(cat <<PROMPT_EOF
# Parallel Task Execution: $task_id

## Spec Directory
$spec_dir

## Task
$task_section

## Requirements Reference
Read $spec_dir/requirements.md for acceptance criteria.

## Design Reference
Read $spec_dir/design.md for architecture details.

## Instructions
1. Implement ONLY this task ($task_id). Do not work on other tasks.
2. Follow existing patterns in the codebase.
3. Wire the code into the application — no isolated files.
4. Update tasks.md: set Status to completed, set Wired appropriately.
5. Make a git commit with a descriptive message.
6. Do NOT update progress.md — the main loop handles that.
PROMPT_EOF
)

  # launch claude in background, writing to log file
  (cd "$task_worktree" && claude --dangerously-skip-permissions -p "$prompt" > "$log_file" 2>&1) &
  local pid=$!

  echo "$pid"
}

# wait_for_batch(pids...)
# Waits for all PIDs to complete. Prints each PID and its exit code.
# Returns 0 if all succeeded, 1 if any failed.
wait_for_batch() {
  local any_failed=0
  for entry in "$@"; do
    # entries may be "pid:task_id" or just "pid"
    local pid="${entry%%:*}"
    local task_id="${entry#*:}"
    local exit_code=0
    wait "$pid" || exit_code=$?

    if [ "$exit_code" -ne 0 ]; then
      echo "Task $task_id (PID $pid) failed with exit code $exit_code" >&2
      any_failed=1
    else
      echo "Task $task_id (PID $pid) completed successfully"
    fi
  done

  return $any_failed
}

# consolidate_parallel_results(spec_dir, completed_tasks, work_dir)
# Merges each task's worktree branch into the main spec branch sequentially.
# On merge conflict: re-queues the task by setting status back to pending.
# Tracks re-queue count — after 3 conflicts, marks task for sequential execution.
consolidate_parallel_results() {
  local spec_dir="$1"
  local completed_tasks="$2"
  local work_dir="$3"

  local spec_name
  spec_name=$(basename "$spec_dir")
  local progress_file="$spec_dir/progress.md"

  for task_id in $completed_tasks; do
    local task_slug
    task_slug=$(echo "$task_id" | tr '[:upper:]' '[:lower:]')
    local branch_name="spec/${spec_name}-${task_slug}"
    local worktree_path=".claude/specs/.worktrees/${spec_name}-${task_slug}"

    # attempt merge
    local merge_output
    merge_output=$(git -C "$work_dir" merge "$branch_name" --no-edit 2>&1)
    local merge_exit=$?

    if [ $merge_exit -ne 0 ]; then
      # merge conflict — abort and re-queue
      git -C "$work_dir" merge --abort 2>/dev/null

      # track re-queue count in tasks.md via a comment
      local requeue_count
      requeue_count=$(_get_requeue_count "$spec_dir/tasks.md" "$task_id")
      requeue_count=$((requeue_count + 1))

      if [ "$requeue_count" -ge 3 ]; then
        # mark for sequential execution by adding a marker
        _set_task_status "$spec_dir/tasks.md" "$task_id" "pending"
        echo "CONFLICT ($task_id): re-queued $requeue_count times — marking for sequential execution" >&2

        # log to progress.md
        {
          echo ""
          echo "## Gate Failure: $task_id"
          echo "- Merge conflict (attempt $requeue_count) — marked for sequential execution"
          echo "- Conflicting branch: $branch_name"
          echo "- Merge output: $(echo "$merge_output" | head -5)"
        } >> "$progress_file"
      else
        _set_task_status "$spec_dir/tasks.md" "$task_id" "pending"
        _set_requeue_count "$spec_dir/tasks.md" "$task_id" "$requeue_count"

        echo "CONFLICT ($task_id): re-queued (attempt $requeue_count)" >&2

        {
          echo ""
          echo "## Merge Conflict: $task_id"
          echo "- Re-queued (attempt $requeue_count of 3)"
          echo "- Branch: $branch_name"
          echo "- Conflict: $(echo "$merge_output" | head -5)"
        } >> "$progress_file"
      fi
    else
      echo "Merged $task_id ($branch_name) successfully"
    fi

    # clean up worktree
    if [ -d "$worktree_path" ]; then
      git worktree remove "$worktree_path" --force 2>/dev/null || true
    fi
  done

  git worktree prune 2>/dev/null
}

# --- Internal helpers ---

# _set_task_status(tasks_file, task_id, new_status)
# Updates the Status field for a task in tasks.md.
_set_task_status() {
  local tasks_file="$1"
  local task_id="$2"
  local new_status="$3"

  # find the task section and update its status line
  local in_task=false
  local tmp_file
  tmp_file=$(mktemp)

  while IFS= read -r line; do
    if [[ "$line" =~ ^###\ ${task_id}: ]]; then
      in_task=true
    elif [[ "$line" =~ ^###\  ]]; then
      in_task=false
    fi

    if $in_task && [[ "$line" =~ ^-\ \*\*Status\*\*: ]]; then
      echo "- **Status**: $new_status" >> "$tmp_file"
    else
      echo "$line" >> "$tmp_file"
    fi
  done < "$tasks_file"

  mv "$tmp_file" "$tasks_file"
}

# _get_requeue_count(tasks_file, task_id)
# Reads the re-queue count from a comment in the task section.
# Returns 0 if no re-queue count found.
_get_requeue_count() {
  local tasks_file="$1"
  local task_id="$2"

  local in_task=false
  while IFS= read -r line; do
    if [[ "$line" =~ ^###\ ${task_id}: ]]; then
      in_task=true
    elif [[ "$line" =~ ^###\  ]]; then
      in_task=false
    fi

    if $in_task && [[ "$line" =~ ^\<!--\ requeue:\ ([0-9]+) ]]; then
      echo "${BASH_REMATCH[1]}"
      return
    fi
  done < "$tasks_file"

  echo "0"
}

# _set_requeue_count(tasks_file, task_id, count)
# Writes or updates the re-queue count comment in the task section.
_set_requeue_count() {
  local tasks_file="$1"
  local task_id="$2"
  local count="$3"

  local in_task=false
  local found_requeue=false
  local tmp_file
  tmp_file=$(mktemp)

  while IFS= read -r line; do
    if [[ "$line" =~ ^###\ ${task_id}: ]]; then
      in_task=true
    elif [[ "$line" =~ ^###\  ]]; then
      # leaving task section — insert requeue comment if not found
      if $in_task && ! $found_requeue; then
        echo "<!-- requeue: $count -->" >> "$tmp_file"
      fi
      in_task=false
    fi

    if $in_task && [[ "$line" =~ ^\<!--\ requeue: ]]; then
      echo "<!-- requeue: $count -->" >> "$tmp_file"
      found_requeue=true
    else
      echo "$line" >> "$tmp_file"
    fi
  done < "$tasks_file"

  # handle case where task is the last section in the file
  if $in_task && ! $found_requeue; then
    echo "<!-- requeue: $count -->" >> "$tmp_file"
  fi

  mv "$tmp_file" "$tasks_file"
}
