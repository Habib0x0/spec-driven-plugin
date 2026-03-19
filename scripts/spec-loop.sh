#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SPEC_NAME=""
USE_WORKTREE=true
MAX_ITERATIONS=50
PROGRESS_TAIL=20

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
    --no-worktree)
      USE_WORKTREE=false
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: spec-loop.sh [--spec-name <name>] [--max-iterations <n>] [--progress-tail <n>] [--no-worktree]"
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

# source shared libraries
source "$SCRIPT_DIR/lib/deps.sh"
source "$SCRIPT_DIR/lib/worktree.sh"
source "$SCRIPT_DIR/lib/checkpoint.sh"

# check cross-spec dependencies before any worktree creation
check_dependencies "$SPEC_NAME"

# setup worktree (sets WORK_DIR)
setup_worktree "$SPEC_NAME" "$USE_WORKTREE"
cd "$WORK_DIR"

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

ITERATION=0

while true; do
  ITERATION=$((ITERATION + 1))
  ITER_START=$(date +%s)
  echo "=== Spec Loop: Iteration $ITERATION / $MAX_ITERATIONS ==="

  # create checkpoint commit before this iteration
  create_checkpoint "$ITERATION" "$WORK_DIR"

  # build fresh prompt each iteration (re-reads spec files to get latest state)
  {
    if [ "$ITERATION" -eq 1 ]; then
      # first iteration: include full spec for context
      echo "# Requirements"
      cat "$SPEC_DIR/requirements.md"
      echo ""
      echo "# Design"
      cat "$SPEC_DIR/design.md"
      echo ""
    else
      # subsequent iterations: reference spec files on disk to cut prompt size
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
    # only include tail of progress to keep prompt small
    if [ -f "$SPEC_DIR/progress.md" ]; then
      # split on --- delimiters, keep header + last N entries
      head -4 "$SPEC_DIR/progress.md"
      grep -c '^---$' "$SPEC_DIR/progress.md" > /dev/null 2>&1 && \
        awk '/^---$/{n++} n>0' "$SPEC_DIR/progress.md" | \
        awk -v tail="$PROGRESS_TAIL" 'BEGIN{n=0} /^---$/{n++} {lines[n]=lines[n] $0 "\n"} END{start=n-tail; if(start<1) start=1; for(i=start;i<=n;i++) printf "%s", lines[i]}' \
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

### Completion
- If ALL tasks have Status: completed AND Wired: yes/n/a AND Verified: yes, output <promise>COMPLETE</promise>
- Otherwise, just complete your one task and exit cleanly.

CRITICAL RULES:
- Only work on ONE task per session.
- Never mark Verified: yes without actually testing end-to-end.
- Never mark Wired: yes without confirming the feature is reachable from the app.
- Never create code in isolation — always wire it into the application.
- Never edit task descriptions — only Status, Wired, and Verified fields.
- Always append to progress.md, never edit previous entries.
- Always leave the codebase in a working state.
EOF
  } > "$PROMPT_FILE"

  # snapshot progress.md before iteration to detect if Claude updated it
  PROGRESS_HASH_BEFORE=""
  if [ -f "$SPEC_DIR/progress.md" ]; then
    PROGRESS_HASH_BEFORE=$(md5 -q "$SPEC_DIR/progress.md" 2>/dev/null || md5sum "$SPEC_DIR/progress.md" 2>/dev/null | cut -d' ' -f1)
  fi

  set +e
  claude --dangerously-skip-permissions -p "$(cat "$PROMPT_FILE")" | tee "$OUTPUT_FILE"
  CLAUDE_EXIT=${PIPESTATUS[0]}
  set -e

  # handle checkpoint recovery on failure
  handle_checkpoint_recovery "$CLAUDE_EXIT" "$CHECKPOINT_SHA" "$ITERATION" "$WORK_DIR"

  # if Claude didn't update progress.md, append a fallback entry
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
    echo "- Note: Claude did not update progress.md this iteration. Check git log for what changed." >> "$SPEC_DIR/progress.md"
    echo "WARNING: progress.md was not updated by iteration $ITERATION — fallback entry appended."
  fi

  if grep -q '<promise>COMPLETE</promise>' "$OUTPUT_FILE"; then
    echo ""
    echo "All tasks complete and verified!"
    print_pr_suggestion "$SPEC_NAME"
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
