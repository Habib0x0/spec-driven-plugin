#!/bin/bash
set -e

# ==============================================================================
# spec-exec.sh — Single iteration of spec-driven implementation
#
# Improvements over v1:
#   1. Pre-computed task brief (eliminates cold start overhead)
#   2. Per-iteration timeout + stall detection
#   3. Per-iteration log file
#   4. learnings.md context carry-forward
#   5. Smart task selection (unblock-count heuristic)
#   6. --skip-e2e flag
#   7. --task flag to target a specific task ID
# ==============================================================================

SPEC_NAME=""
ITERATION_TIMEOUT=1200  # 20 minutes default
HEARTBEAT_INTERVAL=120  # 2 minutes
SKIP_E2E=false
TASK_ID=""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/task-parser.sh"

# parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --spec-name)
      SPEC_NAME="$2"
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
    --task)
      TASK_ID="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: spec-exec.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --spec-name <name>       Spec to execute (auto-detected if only one)"
      echo "  --timeout <seconds>      Timeout for execution (default: 1200 = 20min)"
      echo "  --skip-e2e               Skip Playwright/e2e verification"
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

# Setup directories and files
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

# ==============================================================================
# Smart task selection
# ==============================================================================

TASK_BRIEF=""
CURRENT_TASK_ID=""

if [ -n "$TASK_ID" ]; then
  TASK_BRIEF=$(generate_task_brief "$SPEC_DIR/tasks.md" "$TASK_ID")
  CURRENT_TASK_ID="$TASK_ID"
  echo "Task: $TASK_ID (explicitly requested)"
else
  TASK_BRIEF=$(get_next_task "$SPEC_DIR/tasks.md")
  CURRENT_TASK_ID=$(echo "$TASK_BRIEF" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['id'] if d else '')" 2>/dev/null || echo "")
  if [ -n "$CURRENT_TASK_ID" ]; then
    TASK_TITLE=$(echo "$TASK_BRIEF" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('title',''))" 2>/dev/null || echo "")
    echo "Task: $CURRENT_TASK_ID — $TASK_TITLE (smart selection)"
  else
    echo "No actionable tasks found."
    exit 0
  fi
fi

# ==============================================================================
# Build prompt
# ==============================================================================

PROMPT_FILE=$(mktemp)
LOG_FILE="$LOG_DIR/exec-$(date +%Y%m%d-%H%M%S).log"
trap "rm -f $PROMPT_FILE" EXIT

{
  echo "# Requirements"
  cat "$SPEC_DIR/requirements.md"
  echo ""
  echo "# Design"
  cat "$SPEC_DIR/design.md"
  echo ""
  echo "# Tasks"
  cat "$SPEC_DIR/tasks.md"
  echo ""
  echo "# Codebase Learnings (from previous iterations)"
  cat "$SPEC_DIR/learnings.md"
  echo ""
  echo "# Recent Progress"
  tail -c 2000 "$SPEC_DIR/progress.md"
  echo ""
  
  # Pre-computed task brief
  echo "# YOUR ASSIGNED TASK"
  echo ""
  if [ -n "$TASK_BRIEF" ] && [ "$TASK_BRIEF" != "null" ]; then
    echo '```json'
    echo "$TASK_BRIEF"
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
- Otherwise, just complete your one task and exit cleanly.

CRITICAL RULES:
- Only work on ONE task per session.
- Never mark Verified: yes without actually testing end-to-end.
- Never mark Wired: yes without confirming the feature is reachable from the app.
- Never create code in isolation — always wire it into the application.
- Never edit task descriptions — only Status, Wired, and Verified fields.
- Always append to progress.md, never edit previous entries.
- Always append new learnings to learnings.md.
- Always leave the codebase in a working state.
EOF
} > "$PROMPT_FILE"

echo "=== Running spec-exec for: $SPEC_NAME ==="
echo "Log: $LOG_FILE"
echo ""

START_TIME=$(date +%s)

# Run with timeout
if command -v gtimeout &>/dev/null; then
  TIMEOUT_CMD="gtimeout"
elif command -v timeout &>/dev/null; then
  TIMEOUT_CMD="timeout"
else
  TIMEOUT_CMD=""
fi

EXIT_CODE=0
if [ -n "$TIMEOUT_CMD" ]; then
  $TIMEOUT_CMD "$ITERATION_TIMEOUT" claude --dangerously-skip-permissions "$(cat $PROMPT_FILE)" 2>&1 | tee "$LOG_FILE" || EXIT_CODE=$?
else
  claude --dangerously-skip-permissions "$(cat $PROMPT_FILE)" 2>&1 | tee "$LOG_FILE" || EXIT_CODE=$?
fi

END_TIME=$(date +%s)
DURATION_MS=$(( (END_TIME - START_TIME) * 1000 ))

if [ "$EXIT_CODE" -eq 124 ]; then
  echo ""
  echo "⏱️  Execution timed out after ${ITERATION_TIMEOUT}s."
fi

# Emit structured completion signal
echo ""
echo "{\"event\": \"task_complete\", \"task\": \"$CURRENT_TASK_ID\", \"status\": \"$([ $EXIT_CODE -eq 0 ] && echo 'completed' || echo 'failed')\", \"duration_ms\": $DURATION_MS}"
