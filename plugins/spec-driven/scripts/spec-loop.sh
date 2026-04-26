#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/spec-root.sh"
source "$SCRIPT_DIR/lib/agent-runner.sh"
source "$SCRIPT_DIR/lib/detect-backend.sh"
SPEC_ROOT="$(detect_spec_root)"

SPEC_NAME=""
MAX_ITERATIONS=50
PROGRESS_TAIL=20
ON_COMPLETE=""

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
    --progress-tail)
      PROGRESS_TAIL="$2"
      shift 2
      ;;
    --on-complete)
      ON_COMPLETE="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: spec-loop.sh [--spec-name <name>] [--max-iterations <n>] [--progress-tail <n>] [--on-complete <command>]"
      exit 1
      ;;
  esac
done

# auto-detect spec if not provided
if [ -z "$SPEC_NAME" ]; then
  if [ ! -d "$SPEC_ROOT" ]; then
    echo "Error: No specs directory found at $SPEC_ROOT."
    echo "Run /spec <name> first to create a spec."
    exit 1
  fi

  mapfile -t SPECS < <(list_specs "$SPEC_ROOT")

  if [ ${#SPECS[@]} -eq 0 ]; then
    echo "Error: No specs found in $SPEC_ROOT/"
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

SPEC_DIR="$SPEC_ROOT/$SPEC_NAME"

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

# source shared libraries
source "$SCRIPT_DIR/lib/deps.sh"
source "$SCRIPT_DIR/lib/checkpoint.sh"
source "$SCRIPT_DIR/lib/detect-backend.sh"

# source verify.sh with defensive guard
if [ -f "$SCRIPT_DIR/lib/verify.sh" ]; then
  source "$SCRIPT_DIR/lib/verify.sh"
fi
if ! type run_verification_gate &>/dev/null; then
  echo "WARNING: verify.sh not loaded -- verification gates disabled."
  run_verification_gate() { return 0; }
  run_debugger_fix() { return 0; }
fi

# check cross-spec dependencies
check_dependencies "$SPEC_NAME"

# create progress.md if it doesn't exist
if [ ! -f "$SPEC_DIR/progress.md" ]; then
  echo "# Progress Log: $SPEC_NAME" > "$SPEC_DIR/progress.md"
  echo "" >> "$SPEC_DIR/progress.md"
  echo "> Append-only session log. Do NOT edit previous entries." >> "$SPEC_DIR/progress.md"
  echo "" >> "$SPEC_DIR/progress.md"
  echo "---" >> "$SPEC_DIR/progress.md"
fi

OUTPUT_FILE=$(mktemp)
PROMPT_FILE=$(mktemp)
trap "rm -f $OUTPUT_FILE $PROMPT_FILE" EXIT

WORK_DIR="$(pwd)"

# all_tasks_complete(tasks_file)
# Returns 0 if every task is completed, wired, AND verified.
all_tasks_complete() {
  local tasks_file="$1"
  local has_pending
  has_pending=$(grep -cE '^\- \*\*Status\*\*: (pending|in_progress)' "$tasks_file" 2>/dev/null || true)
  has_pending=${has_pending:-0}
  local has_unverified
  has_unverified=$(grep -c '^\- \*\*Verified\*\*: no' "$tasks_file" 2>/dev/null || true)
  has_unverified=${has_unverified:-0}
  local has_unwired
  has_unwired=$(grep -c '^\- \*\*Wired\*\*: no' "$tasks_file" 2>/dev/null || true)
  has_unwired=${has_unwired:-0}
  [ "$has_pending" -eq 0 ] && [ "$has_unverified" -eq 0 ] && [ "$has_unwired" -eq 0 ]
}

# print_pr_suggestion(spec_name)
print_pr_suggestion() {
  local spec_name="$1"
  echo ""
  echo "Suggested next steps:"
  echo "  git push && gh pr create --title \"$spec_name\""
}

ITERATION=0

# run_gate_with_retry(task_id)
# Runs the verification gate for a task with up to 2 debugger fix retries.
run_gate_with_retry() {
  local task_id="$1"
  echo "Running verification gate for $task_id..."
  local gate_output
  gate_output=$(run_verification_gate "$SPEC_DIR" "$task_id" "$WORK_DIR" 2>&1)
  local gate_exit=$?

  if [ $gate_exit -ne 0 ]; then
    echo "Verification gate FAILED for $task_id: $gate_output"
    local fix_success=false

    for fix_attempt in 1 2; do
      echo "Debugger fix attempt $fix_attempt/2 for $task_id..."
      run_debugger_fix "$SPEC_DIR" "$task_id" "$gate_output" "$WORK_DIR"
      local fix_exit=$?

      if [ $fix_exit -eq 0 ]; then
        local recheck_output
        recheck_output=$(run_verification_gate "$SPEC_DIR" "$task_id" "$WORK_DIR" 2>&1)
        local recheck_exit=$?
        if [ $recheck_exit -eq 0 ]; then
          echo "Verification gate PASSED after fix attempt $fix_attempt."
          fix_success=true
          break
        fi
        gate_output="$recheck_output"
      fi
    done

    if [ "$fix_success" = false ]; then
      echo "Verification gate still failing after 2 fix attempts. Logging and continuing."
      {
        echo ""
        echo "## Gate Failure: $task_id"
        echo "- Date: $(date '+%Y-%m-%d %H:%M')"
        echo "- Gap: $gate_output"
        echo "- Fix attempts: 2 (both failed)"
      } >> "$SPEC_DIR/progress.md"
    fi
  else
    echo "Verification gate PASSED for $task_id."
  fi
}

while true; do
  ITERATION=$((ITERATION + 1))
  ITER_START=$(date +%s)
  echo "=== Spec Loop: Iteration $ITERATION / $MAX_ITERATIONS ==="

  # check if all tasks are already done
  if all_tasks_complete "$SPEC_DIR/tasks.md"; then
    echo ""
    echo "All tasks complete!"
    print_pr_suggestion "$SPEC_NAME"
    break
  fi

  create_checkpoint "$ITERATION" "$WORK_DIR"

  # build fresh prompt each iteration (re-reads spec files to get latest state)
  {
    if [ "$ITERATION" -eq 1 ]; then
      echo "# Requirements"
      cat "$SPEC_DIR/requirements.md"
      echo ""
      echo "# Design"
      cat "$SPEC_DIR/design.md"
      echo ""
    else
      echo "# Spec Reference"
      echo "Requirements and Design are unchanged. Read these files ONLY if you need to check acceptance criteria or architecture:"
      echo "- $(pwd)/$SPEC_DIR/requirements.md"
      echo "- $(pwd)/$SPEC_DIR/design.md"
      echo ""
    fi
    echo "# Tasks"
    cat "$SPEC_DIR/tasks.md"
    echo ""
    echo "# Progress Log (last $PROGRESS_TAIL entries)"
    if [ -f "$SPEC_DIR/progress.md" ]; then
      head -4 "$SPEC_DIR/progress.md"
      grep -c '^---$' "$SPEC_DIR/progress.md" > /dev/null 2>&1 && \
        awk '/^---$/{n++} n>0' "$SPEC_DIR/progress.md" | \
        awk -v tail="$PROGRESS_TAIL" 'BEGIN{n=0} /^---$/{n++} {lines[n]=lines[n] $0 "\n"} END{start=n-tail+1; if(start<1) start=1; for(i=start;i<=n;i++) printf "%s", lines[i]}' \
        || cat "$SPEC_DIR/progress.md"
    fi
    if [ "$ITERATION" -eq 1 ]; then
      cat << 'FIRST_ITER'

## Instructions

### Step 1: Get Your Bearings
1. Run `pwd` to see where you are.
2. Read the Progress Log above to understand what happened in previous sessions.
3. Check git log to see recent commits.
4. If init.sh exists in the spec directory, read it to understand how to run the app.
5. Run a basic health check — start the dev server if needed, verify the app/tests still work before making changes.
FIRST_ITER
    else
      cat << 'NEXT_ITER'

## Instructions

### Step 1: Quick Context Check
1. Read the Progress Log above. Check git log --oneline -5 for recent changes.
2. Only start the dev server or run health checks if the previous iteration reported issues.
NEXT_ITER
    fi
    cat << 'EOF'

### Step 2: Pick ONE Task
1. Find the highest-priority task that is NOT yet verified.
2. Only work on that ONE task. Do not try to do multiple tasks.
3. Respect dependencies — don't start a task if its dependencies aren't completed.

### Step 3: Implement
1. Write the code for the task.
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

### Step 4: Integration Check (MANDATORY before testing)
1. **Can a user reach this feature?** Navigate from the app's entry point to the new feature using normal UI interactions (clicking links, menu items, buttons).
2. If the feature is a backend-only change, verify the endpoint is registered and callable.
3. If the feature requires UI changes, verify the UI element is visible and interactive.
4. **If the code is NOT wired in, DO NOT proceed to testing. Fix the wiring first.**
5. Set **Wired: yes** in tasks.md only after confirming the integration chain is complete.
6. For infrastructure/setup tasks with nothing to wire, set **Wired: n/a**.

### Step 5: Test and Verify
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

### Step 6: Update tasks.md
1. Set Status, Wired, and Verified fields appropriately.
2. Do NOT edit task descriptions, acceptance criteria, or dependencies — only Status, Wired, and Verified.

### Step 7: Update progress.md (MANDATORY)
Append a `---` delimiter followed by a session entry. This MUST happen every iteration. Include:
- What you worked on
- What you completed and verified
- **Integration status**: How the feature is wired in, what connects to what
- Any issues encountered and how you resolved them
- What should be worked on next

### Step 8: Commit
1. Make a git commit with a descriptive message.
2. The commit should leave the codebase in a clean, working state.

### Completion — Integration Sweep (MANDATORY before declaring COMPLETE)
- If ALL tasks have Status: completed AND Wired: yes/n/a AND Verified: yes, run a FULL INTEGRATION SWEEP before outputting <promise>COMPLETE</promise>:
  1. Start the application (if not already running)
  2. Navigate through EVERY user-facing feature from the main entry point
  3. For each feature: verify it renders real content (not stubs), responds to interaction, and shows real data
  4. Check that navigation between features works (sidebar links, breadcrumbs, back buttons)
  5. Run the full test suite if one exists
  6. If ANY feature is broken, stubbed, or unreachable:
     - Do NOT output <promise>COMPLETE</promise>
     - Fix the issue as your ONE task for this iteration
     - Mark the affected task's Verified back to "no" in tasks.md
     - Log the regression in progress.md
  7. Only output <promise>COMPLETE</promise> after the sweep passes with zero issues
- If NOT all tasks are complete, just complete your one task and exit cleanly.

CRITICAL RULES:
- Only work on ONE task per session (exception: the final integration sweep).
- Never mark Verified: yes without actually testing end-to-end.
- Never mark Wired: yes without confirming the feature is reachable from the app.
- Never create code in isolation — always wire it into the application.
- Never create stubs or placeholders — every feature must be fully functional.
- Never edit task descriptions — only Status, Wired, and Verified fields.
- Always append to progress.md, never edit previous entries.
- Always leave the codebase in a working state.
EOF
  } > "$PROMPT_FILE"

  # snapshot completed task IDs before iteration to detect which task was just completed
  COMPLETED_BEFORE=$(grep -B2 '^\- \*\*Status\*\*: completed' "$SPEC_DIR/tasks.md" | grep '^### T-' | sed 's/^### \(T-[0-9]*\(\.[0-9]*\)\{0,1\}\).*/\1/' | sort || echo "")

  # snapshot progress.md before iteration to detect if the agent updated it
  PROGRESS_HASH_BEFORE=""
  if [ -f "$SPEC_DIR/progress.md" ]; then
    PROGRESS_HASH_BEFORE=$(md5 -q "$SPEC_DIR/progress.md" 2>/dev/null || md5sum "$SPEC_DIR/progress.md" 2>/dev/null | cut -d' ' -f1)
  fi

  set +e
  run_agent_prompt_file "$PROMPT_FILE" | tee "$OUTPUT_FILE"
  AGENT_EXIT=${PIPESTATUS[0]}
  set -e

  # handle checkpoint recovery on failure
  handle_checkpoint_recovery "$AGENT_EXIT" "$CHECKPOINT_SHA" "$ITERATION" "$WORK_DIR"

  # if the agent didn't update progress.md, append a fallback entry
  PROGRESS_HASH_AFTER=""
  if [ -f "$SPEC_DIR/progress.md" ]; then
    PROGRESS_HASH_AFTER=$(md5 -q "$SPEC_DIR/progress.md" 2>/dev/null || md5sum "$SPEC_DIR/progress.md" 2>/dev/null | cut -d' ' -f1)
  fi
  if [ "$PROGRESS_HASH_BEFORE" = "$PROGRESS_HASH_AFTER" ]; then
    echo "" >> "$SPEC_DIR/progress.md"
    echo "---" >> "$SPEC_DIR/progress.md"
    echo "" >> "$SPEC_DIR/progress.md"
    echo "## Iteration $ITERATION (auto-logged)" >> "$SPEC_DIR/progress.md"
    echo "- Date: $(date '+%Y-%m-%d %H:%M')" >> "$SPEC_DIR/progress.md"
    echo "- Note: the agent did not update progress.md this iteration. Check git log for what changed." >> "$SPEC_DIR/progress.md"
    echo "WARNING: progress.md was not updated by iteration $ITERATION — fallback entry appended."
  fi

  # verification gate for tasks completed THIS iteration
  COMPLETED_AFTER=$(grep -B2 '^\- \*\*Status\*\*: completed' "$SPEC_DIR/tasks.md" | grep '^### T-' | sed 's/^### \(T-[0-9]*\(\.[0-9]*\)\{0,1\}\).*/\1/' | sort || echo "")
  while IFS= read -r NEWLY_COMPLETED; do
    [ -n "$NEWLY_COMPLETED" ] && run_gate_with_retry "$NEWLY_COMPLETED"
  done < <(comm -13 <(echo "$COMPLETED_BEFORE") <(echo "$COMPLETED_AFTER"))

  if grep -q '<promise>COMPLETE</promise>' "$OUTPUT_FILE"; then
    echo ""
    echo "All tasks complete and verified!"
    print_pr_suggestion "$SPEC_NAME"
    if [ -n "$ON_COMPLETE" ]; then
      echo ""
      echo "Running on-complete hook: $ON_COMPLETE"
      eval "$ON_COMPLETE"
    fi
    break
  fi

  if [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
    echo ""
    echo "Max iterations reached ($MAX_ITERATIONS)"
    break
  fi

  ITER_END=$(date +%s)
  ITER_DURATION=$((ITER_END - ITER_START))
  echo ""
  echo "--- Iteration $ITERATION done in ${ITER_DURATION}s. Continuing... ---"
  echo ""
done
