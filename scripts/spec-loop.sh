#!/bin/bash
set -e

SPEC_NAME=""
MAX_ITERATIONS=50

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
    *)
      echo "Unknown argument: $1"
      echo "Usage: spec-loop.sh [--spec-name <name>] [--max-iterations <n>]"
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
  echo "=== Spec Loop: Iteration $ITERATION / $MAX_ITERATIONS ==="

  # build fresh prompt each iteration (re-reads spec files to get latest state)
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
    echo "# Progress Log"
    cat "$SPEC_DIR/progress.md"
    cat << 'EOF'

## Instructions

### Step 1: Get Your Bearings
1. Run `pwd` to see where you are.
2. Read the Progress Log above to understand what happened in previous sessions.
3. Check git log to see recent commits.
4. Run a basic health check — verify the app/tests still work before making changes.

### Step 2: Pick ONE Task
1. Find the highest-priority task that is NOT yet verified.
2. Only work on that ONE task. Do not try to do multiple tasks.

### Step 3: Implement
1. Write the code for the task.
2. Follow existing patterns in the codebase.

### Step 4: Test and Verify
1. Run the relevant tests (unit, integration, e2e as appropriate).
2. Manually verify the feature works end-to-end if applicable.
3. It is UNACCEPTABLE to mark a task as verified without actually testing it.
4. Only set **Verified: yes** after you have confirmed the acceptance criteria pass.

### Step 5: Update Spec Files
1. Update tasks.md: set Status to "completed" and Verified to "yes" (only if actually verified).
2. Do NOT edit task descriptions, acceptance criteria, or dependencies — only Status and Verified.
3. Append a session entry to progress.md with:
   - What you worked on
   - What you completed and verified
   - Any issues encountered and how you resolved them
   - What should be worked on next

### Step 6: Commit
1. Make a git commit with a descriptive message.
2. The commit should leave the codebase in a clean, working state.

### Completion
- If ALL tasks have Status: completed AND Verified: yes, output <promise>COMPLETE</promise>
- Otherwise, just complete your one task and exit cleanly.

CRITICAL RULES:
- Only work on ONE task per session.
- Never mark Verified: yes without actually testing.
- Never edit task descriptions — only Status and Verified fields.
- Always append to progress.md, never edit previous entries.
- Always leave the codebase in a working state.
EOF
  } > "$PROMPT_FILE"

  claude --dangerously-skip-permissions "$(cat $PROMPT_FILE)" | tee "$OUTPUT_FILE"

  if grep -q '<promise>COMPLETE</promise>' "$OUTPUT_FILE"; then
    echo ""
    echo "All tasks complete and verified!"
    break
  fi

  if [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
    echo ""
    echo "Max iterations reached ($MAX_ITERATIONS)"
    break
  fi

  echo ""
  echo "--- Iteration $ITERATION done. Continuing... ---"
  echo ""
done
