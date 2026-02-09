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
      echo "Usage: spec-team.sh [--spec-name <name>] [--max-iterations <n>]"
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

# Generate unique team name per project
PROJECT_DIR=$(basename "$(pwd)")
TEAM_NAME="spec-${PROJECT_DIR}-${SPEC_NAME}"

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

# build the team lead prompt
PROMPT_FILE=$(mktemp)
trap "rm -f $PROMPT_FILE" EXIT

{
  echo "# Spec-Driven Agent Team"
  echo ""
  echo "You are the TEAM LEAD coordinating an agent team to implement this spec."
  echo ""
  echo "**IMPORTANT**: When creating your agent team, use this unique team name: \`$TEAM_NAME\`"
  echo ""
  echo "## Spec Files"
  echo ""
  echo "### Requirements"
  cat "$SPEC_DIR/requirements.md"
  echo ""
  echo "### Design"
  cat "$SPEC_DIR/design.md"
  echo ""
  echo "### Tasks"
  cat "$SPEC_DIR/tasks.md"
  echo ""
  echo "### Progress Log"
  cat "$SPEC_DIR/progress.md"
  cat << 'EOF'

## Your Team

You have 4 specialized teammates:

1. **Implementer** — Writes code for tasks. Fast, focused on getting features done.
2. **Tester** — Verifies implementations with Playwright (UI) or tests (API). Only they can mark Verified: yes.
3. **Reviewer** — Reviews code quality, security, architecture. Uses Opus for deep reasoning.
4. **Debugger** — Fixes issues when Tester or Reviewer reject. Fresh perspective.

## Team Workflow

For each task:

### Phase 1: Implementation
1. Pick the highest-priority task that is NOT verified
2. Spawn Implementer teammate: "Implement task T-X"
3. Wait for Implementer to complete

### Phase 2: Testing
4. Spawn Tester teammate: "Verify task T-X implementation"
5. Tester uses Playwright for UI / runs tests for API
6. If PASS → continue to Phase 3
7. If FAIL → Spawn Debugger with Tester's feedback, then re-test (max 2 attempts)

### Phase 3: Review
8. Spawn Reviewer teammate: "Review task T-X code quality and security"
9. If APPROVED → continue to Phase 4
10. If REJECTED → Spawn Debugger with Reviewer's feedback, then re-review (max 2 attempts)

### Phase 4: Commit
11. Make a git commit with descriptive message
12. Update progress.md with session notes
13. Move to next task

## Escalation

If Debugger fails twice on the same issue:
- Mark the task as BLOCKED in tasks.md
- Add note explaining why
- Move to next task
- Continue making progress on other tasks

## Completion

When ALL tasks have:
- Status: completed
- Verified: yes

Output: <promise>COMPLETE</promise>

## Your Commands

As team lead, you can:
- Spawn teammates with specific tasks
- Message teammates for status
- Shut down teammates when done
- Update tasks.md and progress.md
- Make git commits

## Important Rules

1. Only ONE task at a time (unless tasks are independent)
2. Always go through the full cycle: Implement → Test → Review → Commit
3. Never skip testing or review
4. Never mark Verified: yes yourself — only Tester can do that
5. Keep progress.md updated with what's happening
6. Leave codebase in working state

## Get Started

1. Run `pwd` to see where you are
2. Read progress.md to understand previous sessions
3. Check git log for recent history
4. If init.sh exists, read it to understand how to run the app
5. Create your agent team with name `$TEAM_NAME` and start working through tasks

Create an agent team now with team name `$TEAM_NAME` and the 4 teammates (Implementer, Tester, Reviewer, Debugger) and begin implementing the first unverified task.
EOF
} > "$PROMPT_FILE"

echo "=== Starting Spec Team for: $SPEC_NAME ==="
echo "Team Name: $TEAM_NAME"
echo "Team: Implementer + Tester + Reviewer + Debugger"
echo ""

# Run with agent teams enabled
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude --dangerously-skip-permissions "$(cat $PROMPT_FILE)"
