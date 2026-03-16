#!/bin/bash
set -e

# ==============================================================================
# spec-loop.sh — Autonomous spec implementation loop
#
# Improvements over v1:
#   1. Pre-computed task briefs (eliminates cold start overhead)
#   2. Per-iteration timeout + stall detection
#   3. Per-iteration log files + progress.json
#   4. learnings.md context carry-forward
#   5. Smart task selection (unblock-count heuristic)
#   6. Task batching for same-phase independent tasks
#   7. --skip-e2e flag for non-UI / Docker environments
#   8. Structured completion signals (JSON events)
#   9. Parallel execution via dependency DAG (--parallel flag)
# ==============================================================================

SPEC_NAME=""
MAX_ITERATIONS=50
ITERATION_TIMEOUT=1200  # 20 minutes default
HEARTBEAT_INTERVAL=120  # 2 minutes
SKIP_E2E=false
PARALLEL=false
BATCH_MODE=false
BATCH_SIZE=3
TASK_ID=""  # optional: run a specific task

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/task-parser.sh"

# parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --spec-name)
      SPEC_NAME="$2"
      shift 2
      ;;
    --max-iterations)
      MAX_ITERATIONS="$2"
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
    --parallel)
      PARALLEL=true
      shift
      ;;
    --batch)
      BATCH_MODE=true
      shift
      ;;
    --batch-size)
      BATCH_SIZE="$2"
      shift 2
      ;;
    --task)
      TASK_ID="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: spec-loop.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --spec-name <name>       Spec to execute (auto-detected if only one)"
      echo "  --max-iterations <n>     Max iterations (default: 50)"
      echo "  --timeout <seconds>      Per-iteration timeout (default: 1200 = 20min)"
      echo "  --skip-e2e               Skip Playwright/e2e verification"
      echo "  --parallel               Run independent tasks in parallel worktrees"
      echo "  --batch                  Batch same-phase tasks into single sessions"
      echo "  --batch-size <n>         Max tasks per batch (default: 3)"
      echo "  --task <T-XX>            Run a specific task ID"
      exit 1
      ;;
  esac
done

# auto-detect spec if not provided
if [ -z "$SPEC_NAME" ]; then
  if [ ! -d ".claude/specs" ]; then
    echo "Error: No .claude/specs directory found."
    echo "Run /spec <name> first to create a spec."
    exit 1
  fi

  SPECS=($(ls -d .claude/specs/*/  2>/dev/null | xargs -I{} basename {}))

  if [ ${#SPECS[@]} -eq 0 ]; then
    echo "Error: No specs found in .claude/specs/"
    exit 1
  elif [ ${#SPECS[@]} -eq 1 ]; then
    SPEC_NAME="${SPECS[0]}"
    echo "Auto-detected spec: $SPEC_NAME"
  else
    echo "Error: Multiple specs found. Please specify one with --spec-name:"
    for s in "${SPECS[@]}"; do
      echo "  $s"
    done
    exit 1
  fi
fi

SPEC_DIR=".claude/specs/$SPEC_NAME"

if [ ! -d "$SPEC_DIR" ]; then
  echo "Error: Spec directory not found: $SPEC_DIR"
  exit 1
fi

for f in requirements.md design.md tasks.md; do
  if [ ! -f "$SPEC_DIR/$f" ]; then
    echo "Error: Missing $f in $SPEC_DIR"
    exit 1
  fi
done

# ==============================================================================
# Setup directories and files
# ==============================================================================

LOG_DIR="$SPEC_DIR/logs"
mkdir -p "$LOG_DIR"

# create progress.md if it doesn't exist
if [ ! -f "$SPEC_DIR/progress.md" ]; then
  echo "# Progress Log: $SPEC_NAME" > "$SPEC_DIR/progress.md"
  echo "" >> "$SPEC_DIR/progress.md"
  echo "> Append-only session log. Do NOT edit previous entries." >> "$SPEC_DIR/progress.md"
  echo "" >> "$SPEC_DIR/progress.md"
  echo "---" >> "$SPEC_DIR/progress.md"
fi

# create learnings.md if it doesn't exist
if [ ! -f "$SPEC_DIR/learnings.md" ]; then
  cat > "$SPEC_DIR/learnings.md" << 'LEARNINGS_EOF'
# Codebase Learnings

> Discovered during implementation. Each iteration should READ this before starting
> and APPEND any new discoveries. Do NOT edit previous entries.

---

LEARNINGS_EOF
fi

# Initialize progress.json
PROGRESS_JSON="$SPEC_DIR/logs/progress.json"
STATUSES=$(count_task_statuses "$SPEC_DIR/tasks.md")
TOTAL=$(echo "$STATUSES" | python3 -c "import json,sys; print(json.load(sys.stdin)['total'])")
VERIFIED=$(echo "$STATUSES" | python3 -c "import json,sys; print(json.load(sys.stdin)['verified'])")
cat > "$PROGRESS_JSON" << PJEOF
{"completed": $VERIFIED, "total": $TOTAL, "last_task": null, "last_iteration": 0, "status": "running", "started": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
PJEOF

PROMPT_FILE=$(mktemp)
trap "rm -f $PROMPT_FILE" EXIT

# ==============================================================================
# Build the task-specific prompt (pre-computed brief instead of full spec dump)
# ==============================================================================
build_prompt() {
  local task_brief="$1"  # JSON task brief
  local batch_briefs="$2"  # Optional: JSON array of task briefs for batch mode
  
  {
    # Always include full spec context, but highlight the specific task
    echo "# Requirements"
    cat "$SPEC_DIR/requirements.md"
    echo ""
    echo "# Design"
    cat "$SPEC_DIR/design.md"
    echo ""
    echo "# Tasks"
    cat "$SPEC_DIR/tasks.md"
    echo ""
    
    # Include learnings from previous iterations
    echo "# Codebase Learnings (from previous iterations)"
    cat "$SPEC_DIR/learnings.md"
    echo ""
    
    # Include recent progress (last 2000 chars to avoid bloat)
    echo "# Recent Progress"
    tail -c 2000 "$SPEC_DIR/progress.md"
    echo ""
    
    # Pre-computed task brief — this is the key optimization
    echo "# YOUR ASSIGNED TASK"
    echo ""
    if [ -n "$batch_briefs" ] && [ "$batch_briefs" != "null" ]; then
      echo "## Batch Mode: You have been assigned MULTIPLE related tasks"
      echo ""
      echo '```json'
      echo "$batch_briefs"
      echo '```'
      echo ""
      echo "These tasks are in the same phase and have no mutual dependencies."
      echo "Implement ALL of them in this session."
    elif [ -n "$task_brief" ] && [ "$task_brief" != "null" ]; then
      echo '```json'
      echo "$task_brief"
      echo '```'
      echo ""
      echo "Focus on THIS task. Do not work on any other task."
    else
      echo "Find the next highest-priority unverified task and implement it."
    fi
    echo ""
    
    # Skip-e2e instruction
    if [ "$SKIP_E2E" = true ]; then
      echo "## E2E Testing Override"
      echo ""
      echo "**SKIP Playwright/browser-based e2e tests.** The application runs in Docker/deployed"
      echo "mode, not a local dev server. Verify using:"
      echo "- Unit tests (npm test, pytest, etc.)"
      echo "- Integration tests"
      echo "- curl against running endpoints"
      echo "- Code review of wiring"
      echo ""
      echo "Do NOT launch Playwright or attempt webServer-based testing."
      echo ""
    fi
    
    cat << 'EOF'

## Instructions

### Step 1: Get Your Bearings
1. Run `pwd` to see where you are.
2. Read the Codebase Learnings above — these are discoveries from previous sessions. Do NOT repeat mistakes already documented.
3. Check git log -5 to see recent commits.
4. If init.sh exists in the spec directory, read it to understand how to run the app.
5. Run a basic health check — start the dev server if needed, verify the app/tests still work before making changes.
6. **SKIP lengthy codebase scanning** — the task brief above tells you exactly what to do.

### Step 2: Implement
1. Write the code for the task(s).
2. Follow existing patterns in the codebase.
3. **WIRE IT IN**: Do not just create files in isolation. Every piece of code must be connected to the application:
   - New routes must be registered in the router
   - New pages must be linked in navigation (sidebar, menu, header)
   - New components must be imported and rendered in the appropriate page/route
   - New API endpoints must be registered in the server
   - New frontend API calls must be triggered by the appropriate user action
   - Form submissions must call the correct API endpoint
   - API responses must be rendered in the UI
4. After writing code, trace the path from the app's entry point to your new code. If there's a gap, fill it.

### Step 3: Integration Check (MANDATORY before testing)
1. **Can a user reach this feature?** Navigate from the app's entry point to the new feature using normal UI interactions (clicking links, menu items, buttons).
2. If the feature is a backend-only change, verify the endpoint is registered and callable.
3. If the feature requires UI changes, verify the UI element is visible and interactive.
4. **If the code is NOT wired in, DO NOT proceed to testing. Fix the wiring first.**
5. Set **Wired: yes** in tasks.md only after confirming the integration chain is complete.
6. For infrastructure/setup tasks with nothing to wire, set **Wired: n/a**.

### Step 4: Test and Verify
1. Run the relevant tests (unit, integration, e2e as appropriate).
2. For UI features: Use the Playwright MCP to launch a browser and verify the feature works.
   - Start from the app's main entry point (NOT a direct URL to the feature)
   - Navigate to the feature through normal user interactions
   - Interact with the UI as a user would
   - Take screenshots as evidence
   - Also verify via direct URL that the route works
   - Do NOT skip this step for any user-facing feature
3. For API/backend features: Use curl or test commands to verify endpoints work.
4. It is UNACCEPTABLE to mark a task as verified without actually testing it.
5. It is UNACCEPTABLE to mark a task as verified if the feature isn't reachable from the app.
6. Only set **Verified: yes** after you have confirmed:
   - The code is wired into the application (Wired: yes)
   - All acceptance criteria pass when tested end-to-end
   - The feature is reachable through normal user navigation

### Step 5: Update Spec Files
1. Update tasks.md: set Status, Wired, and Verified fields appropriately.
2. Do NOT edit task descriptions, acceptance criteria, or dependencies — only Status, Wired, and Verified.
3. Append a session entry to progress.md with:
   - What you worked on
   - What you completed and verified
   - **Integration status**: How the feature is wired in, what connects to what
   - Any issues encountered and how you resolved them
   - What should be worked on next

### Step 6: Update Learnings (IMPORTANT — context for future iterations)
If you discovered anything non-obvious during this session, APPEND it to learnings.md:
- Codebase gotchas (e.g., "ioredis KEYS doesn't auto-prefix")
- Environment quirks (e.g., "Playwright fails if webServer is configured but app runs in Docker")
- Schema surprises (e.g., "column is `name`, not `xml_id`")
- Pattern notes (e.g., "all services use factory pattern, not direct instantiation")

### Step 7: Commit
1. Make a git commit with a descriptive message.
2. The commit should leave the codebase in a clean, working state.

### Completion
- If ALL tasks have Status: completed AND Wired: yes/n/a AND Verified: yes, output <promise>COMPLETE</promise>
- Otherwise, just complete your task(s) and exit cleanly.

CRITICAL RULES:
- Never mark Verified: yes without actually testing end-to-end.
- Never mark Wired: yes without confirming the feature is reachable from the app.
- Never create code in isolation — always wire it into the application.
- Never edit task descriptions — only Status, Wired, and Verified fields.
- Always append to progress.md, never edit previous entries.
- Always append new learnings to learnings.md.
- Always leave the codebase in a working state.
EOF
  } > "$PROMPT_FILE"
}

# ==============================================================================
# Update progress.json after each iteration
# ==============================================================================
update_progress_json() {
  local iteration="$1"
  local task_id="$2"
  local status="$3"
  local duration_ms="$4"
  
  STATUSES=$(count_task_statuses "$SPEC_DIR/tasks.md")
  VERIFIED=$(echo "$STATUSES" | python3 -c "import json,sys; print(json.load(sys.stdin)['verified'])")
  TOTAL=$(echo "$STATUSES" | python3 -c "import json,sys; print(json.load(sys.stdin)['total'])")
  
  cat > "$PROGRESS_JSON" << PJEOF
{"completed": $VERIFIED, "total": $TOTAL, "last_task": "$task_id", "last_iteration": $iteration, "status": "$status", "updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
PJEOF

  # Emit structured event to stdout for parent session parsing
  echo ""
  echo "{\"event\": \"iteration_complete\", \"iteration\": $iteration, \"task\": \"$task_id\", \"status\": \"$status\", \"duration_ms\": $duration_ms, \"verified\": $VERIFIED, \"total\": $TOTAL}"
}

# ==============================================================================
# Run a single iteration with timeout and heartbeat monitoring
# ==============================================================================
run_iteration_with_timeout() {
  local iteration="$1"
  local log_file="$2"
  
  local start_time=$(date +%s)
  
  # Run claude with timeout, stream output to both log file and stdout
  # The heartbeat is handled by checking if the log file is still growing
  local exit_code=0
  
  if command -v gtimeout &>/dev/null; then
    TIMEOUT_CMD="gtimeout"
  elif command -v timeout &>/dev/null; then
    TIMEOUT_CMD="timeout"
  else
    TIMEOUT_CMD=""
  fi
  
  if [ -n "$TIMEOUT_CMD" ]; then
    $TIMEOUT_CMD "$ITERATION_TIMEOUT" claude --dangerously-skip-permissions "$(cat $PROMPT_FILE)" 2>&1 | tee "$log_file" || exit_code=$?
  else
    # Fallback: use background process + manual timeout check
    claude --dangerously-skip-permissions "$(cat $PROMPT_FILE)" 2>&1 | tee "$log_file" &
    local claude_pid=$!
    
    local last_size=0
    local stall_count=0
    local max_stalls=$((ITERATION_TIMEOUT / HEARTBEAT_INTERVAL))
    
    while kill -0 "$claude_pid" 2>/dev/null; do
      sleep "$HEARTBEAT_INTERVAL"
      
      local current_size=$(wc -c < "$log_file" 2>/dev/null || echo 0)
      if [ "$current_size" -eq "$last_size" ]; then
        stall_count=$((stall_count + 1))
        echo ""
        echo "⚠️  HEARTBEAT: No output for $((stall_count * HEARTBEAT_INTERVAL))s (stall $stall_count/$max_stalls)"
        
        if [ "$stall_count" -ge "$max_stalls" ]; then
          echo ""
          echo "❌ STALL DETECTED: Iteration $iteration stalled for $((stall_count * HEARTBEAT_INTERVAL))s. Killing..."
          kill "$claude_pid" 2>/dev/null || true
          wait "$claude_pid" 2>/dev/null || true
          exit_code=124  # same as timeout exit code
          break
        fi
      else
        stall_count=0
        last_size=$current_size
      fi
      
      # Check elapsed time
      local elapsed=$(( $(date +%s) - start_time ))
      if [ "$elapsed" -ge "$ITERATION_TIMEOUT" ]; then
        echo ""
        echo "❌ TIMEOUT: Iteration $iteration exceeded ${ITERATION_TIMEOUT}s. Killing..."
        kill "$claude_pid" 2>/dev/null || true
        wait "$claude_pid" 2>/dev/null || true
        exit_code=124
        break
      fi
    done
    
    if [ "$exit_code" -eq 0 ]; then
      wait "$claude_pid" 2>/dev/null
      exit_code=$?
    fi
  fi
  
  local end_time=$(date +%s)
  local duration_ms=$(( (end_time - start_time) * 1000 ))
  
  # Return values via global vars (bash limitation)
  ITER_EXIT_CODE=$exit_code
  ITER_DURATION_MS=$duration_ms
}

# ==============================================================================
# Main loop
# ==============================================================================

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           SPEC LOOP: $SPEC_NAME"
echo "║  Max iterations: $MAX_ITERATIONS | Timeout: ${ITERATION_TIMEOUT}s"
echo "║  Skip E2E: $SKIP_E2E | Parallel: $PARALLEL | Batch: $BATCH_MODE"
echo "║  Logs: $LOG_DIR/"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

ITERATION=0

while true; do
  ITERATION=$((ITERATION + 1))
  
  # Per-iteration log file
  LOG_FILE="$LOG_DIR/iteration-$(printf '%03d' $ITERATION).log"
  
  echo "═══════════════════════════════════════════════════════════════"
  echo "  Iteration $ITERATION / $MAX_ITERATIONS — $(date '+%Y-%m-%d %H:%M:%S')"
  echo "═══════════════════════════════════════════════════════════════"
  
  # Smart task selection — pick the task that unblocks the most downstream work
  TASK_BRIEF=""
  BATCH_BRIEFS=""
  CURRENT_TASK_ID=""
  
  if [ -n "$TASK_ID" ]; then
    # Specific task requested
    TASK_BRIEF=$(generate_task_brief "$SPEC_DIR/tasks.md" "$TASK_ID")
    CURRENT_TASK_ID="$TASK_ID"
    echo "  Task: $TASK_ID (explicitly requested)"
  elif [ "$BATCH_MODE" = true ]; then
    # Try to find a batch of same-phase tasks
    BATCH_IDS=$(get_batch_tasks "$SPEC_DIR/tasks.md" "$BATCH_SIZE")
    if [ "$BATCH_IDS" != "null" ] && [ -n "$BATCH_IDS" ]; then
      # Build batch briefs
      BATCH_BRIEFS="["
      FIRST=true
      for tid in $(echo "$BATCH_IDS" | python3 -c "import json,sys; [print(t) for t in json.load(sys.stdin)]"); do
        BRIEF=$(generate_task_brief "$SPEC_DIR/tasks.md" "$tid")
        if [ "$FIRST" = true ]; then
          FIRST=false
        else
          BATCH_BRIEFS="$BATCH_BRIEFS,"
        fi
        BATCH_BRIEFS="$BATCH_BRIEFS$BRIEF"
      done
      BATCH_BRIEFS="$BATCH_BRIEFS]"
      CURRENT_TASK_ID=$(echo "$BATCH_IDS" | python3 -c "import json,sys; print(','.join(json.load(sys.stdin)))")
      echo "  Batch: $CURRENT_TASK_ID"
    else
      # Fall back to single task
      TASK_BRIEF=$(get_next_task "$SPEC_DIR/tasks.md")
      CURRENT_TASK_ID=$(echo "$TASK_BRIEF" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['id'] if d else '')" 2>/dev/null || echo "")
      echo "  Task: $CURRENT_TASK_ID (smart selection, no batch available)"
    fi
  else
    # Smart single-task selection
    TASK_BRIEF=$(get_next_task "$SPEC_DIR/tasks.md")
    CURRENT_TASK_ID=$(echo "$TASK_BRIEF" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['id'] if d else '')" 2>/dev/null || echo "")
    if [ -n "$CURRENT_TASK_ID" ]; then
      TASK_TITLE=$(echo "$TASK_BRIEF" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('title',''))" 2>/dev/null || echo "")
      echo "  Task: $CURRENT_TASK_ID — $TASK_TITLE (smart selection)"
    else
      echo "  No actionable tasks found. Checking if all are complete..."
    fi
  fi
  
  # Check if all tasks are complete
  if [ -z "$CURRENT_TASK_ID" ] && [ "$TASK_BRIEF" = "null" -o -z "$TASK_BRIEF" ]; then
    STATUSES=$(count_task_statuses "$SPEC_DIR/tasks.md")
    PENDING=$(echo "$STATUSES" | python3 -c "import json,sys; print(json.load(sys.stdin)['pending'])")
    if [ "$PENDING" -eq 0 ]; then
      echo ""
      echo "✅ All tasks complete!"
      update_progress_json "$ITERATION" "" "complete" 0
      break
    else
      echo "  ⚠️  Some tasks remaining but none are actionable (blocked by dependencies?)"
    fi
  fi
  
  echo "  Log: $LOG_FILE"
  echo ""
  
  # Build the prompt with pre-computed task brief
  build_prompt "$TASK_BRIEF" "$BATCH_BRIEFS"
  
  # Run with timeout and heartbeat
  run_iteration_with_timeout "$ITERATION" "$LOG_FILE"
  
  # Check results
  if [ "$ITER_EXIT_CODE" -eq 124 ]; then
    echo ""
    echo "⏱️  Iteration $ITERATION timed out after ${ITERATION_TIMEOUT}s. Retrying..."
    update_progress_json "$ITERATION" "$CURRENT_TASK_ID" "timeout" "$ITER_DURATION_MS"
    echo ""
    # Don't count timeouts toward max iterations — retry the same task
    ITERATION=$((ITERATION - 1))
    continue
  fi
  
  if grep -q '<promise>COMPLETE</promise>' "$LOG_FILE" 2>/dev/null; then
    echo ""
    echo "✅ All tasks complete and verified!"
    update_progress_json "$ITERATION" "$CURRENT_TASK_ID" "complete" "$ITER_DURATION_MS"
    break
  fi
  
  # Update progress
  update_progress_json "$ITERATION" "$CURRENT_TASK_ID" "in_progress" "$ITER_DURATION_MS"
  
  if [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
    echo ""
    echo "🛑 Max iterations reached ($MAX_ITERATIONS)"
    update_progress_json "$ITERATION" "$CURRENT_TASK_ID" "max_iterations" "$ITER_DURATION_MS"
    break
  fi
  
  # Clear specific task ID after first iteration (only applies when --task is used)
  if [ -n "$TASK_ID" ]; then
    echo ""
    echo "Single task mode: $TASK_ID complete. Exiting."
    break
  fi
  
  echo ""
  echo "--- Iteration $ITERATION done ($((ITER_DURATION_MS / 1000))s). Continuing... ---"
  echo ""
done

# Final summary
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  SPEC LOOP COMPLETE"
echo "║"
FINAL_STATUSES=$(count_task_statuses "$SPEC_DIR/tasks.md")
echo "║  $(echo "$FINAL_STATUSES" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'Verified: {d[\"verified\"]}/{d[\"total\"]} | Completed: {d[\"completed\"]} | Pending: {d[\"pending\"]} | Blocked: {d[\"blocked\"]}')")"
echo "║  Total iterations: $ITERATION"
echo "║  Logs: $LOG_DIR/"
echo "╚══════════════════════════════════════════════════════════════╝"
