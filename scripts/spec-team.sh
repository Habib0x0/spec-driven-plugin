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

# Generate unique team name using full path hash to avoid cross-project collisions
PROJECT_HASH=$(echo -n "$(pwd)" | shasum -a 256 | cut -c1-8)
TIMESTAMP=$(date +%s)
TEAM_NAME="spec-${PROJECT_HASH}-${SPEC_NAME}-${TIMESTAMP}"

# Store team metadata so we can identify what's running
TEAM_META_DIR="$HOME/.claude/team-meta"
mkdir -p "$TEAM_META_DIR"

# Only clean up dead teams from THIS project + spec combination
LOCK_PATTERN="${PROJECT_HASH}-${SPEC_NAME}"
for meta_file in "$TEAM_META_DIR/$LOCK_PATTERN"-*.json; do
  [ -f "$meta_file" ] || continue
  OLD_PID=$(python3 -c "import json; print(json.load(open('$meta_file')).get('pid',''))" 2>/dev/null || true)
  OLD_TEAM=$(python3 -c "import json; print(json.load(open('$meta_file')).get('team',''))" 2>/dev/null || true)
  if [ -n "$OLD_PID" ] && ! kill -0 "$OLD_PID" 2>/dev/null; then
    # process is dead, safe to clean up
    if [ -n "$OLD_TEAM" ] && [ -d "$HOME/.claude/teams/$OLD_TEAM" ]; then
      echo "Cleaning up stale team: $OLD_TEAM"
      rm -rf "$HOME/.claude/teams/$OLD_TEAM"
    fi
    rm -f "$meta_file"
  elif [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    echo "Warning: Another spec-team is already running for this project+spec (PID $OLD_PID)"
    echo "Run 'kill $OLD_PID' to stop it first, or use a different spec name."
    exit 1
  fi
done

# Write metadata for this session
TEAM_META_FILE="$TEAM_META_DIR/${LOCK_PATTERN}-${TIMESTAMP}.json"

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

# clean up temp files and metadata on exit
cleanup() {
  rm -f "$PROMPT_FILE"
  rm -f "$TEAM_META_FILE"
}
trap cleanup EXIT

{
  echo "# Spec-Driven Agent Team"
  echo ""
  echo "You are the TEAM LEAD coordinating an agent team to implement this spec."
  echo ""
  echo "## CRITICAL: Team Name"
  echo ""
  echo "**YOU MUST USE THIS EXACT TEAM NAME**: \`$TEAM_NAME\`"
  echo ""
  echo "This unique name prevents conflicts with other projects. Do NOT use any other team name."
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

1. **Implementer** — Writes code for tasks AND wires it into the application. Must ensure code is reachable, not just written.
2. **Tester** — Verifies implementations end-to-end with Playwright (UI) or tests (API). Checks integration first, then functionality. Only they can mark Verified: yes.
3. **Reviewer** — Reviews code quality, security, architecture, AND integration completeness. Uses Opus for deep reasoning.
4. **Debugger** — Fixes issues when Tester or Reviewer reject. Specializes in finding wiring gaps and integration failures.

## Team Workflow

For each task:

### Phase 1: Implementation + Wiring
1. Pick the highest-priority task that is NOT verified
2. Spawn Implementer teammate: "Implement task T-X. Write the code AND wire it into the application. The code must be reachable from the app's entry point."
3. Wait for Implementer to complete and confirm Wired: yes

### Phase 2: Integration + Testing
4. Spawn Tester teammate: "Verify task T-X. FIRST check the feature is reachable from the app (integration check). THEN test all acceptance criteria end-to-end."
5. Tester checks integration first, then uses Playwright for UI / runs tests for API
6. If PASS (both integration and functional) → continue to Phase 3
7. If INTEGRATION FAIL → Spawn Debugger: "Feature T-X is not wired into the app. [Tester's details]"
8. If FUNCTIONAL FAIL → Spawn Debugger with Tester's feedback, then re-test (max 2 attempts)

### Phase 3: Review
9. Spawn Reviewer teammate: "Review task T-X code quality, security, and integration completeness"
10. If APPROVED → continue to Phase 4
11. If REJECTED → Spawn Debugger with Reviewer's feedback, then re-review (max 2 attempts)

### Phase 4: Commit
12. Make a git commit with descriptive message
13. Update progress.md with session notes including integration status
14. Move to next task

## Escalation

If Debugger fails twice on the same issue:
- Mark the task as BLOCKED in tasks.md
- Add note explaining why (especially if it's a wiring issue)
- Move to next task
- Continue making progress on other tasks

## Completion

When ALL tasks have:
- Status: completed
- Wired: yes (or n/a for infrastructure tasks)
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
2. Always go through the full cycle: Implement+Wire → Integration Check → Test → Review → Commit
3. Never skip integration checking or testing or review
4. Never mark Verified: yes yourself — only Tester can do that
5. Never accept "code is written" without "code is wired in"
6. Keep progress.md updated with integration status
7. Leave codebase in working state

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
echo "Project: $(pwd)"
echo "Team: Implementer + Tester + Reviewer + Debugger"
echo ""

# write metadata so other sessions know we're running
cat > "$TEAM_META_FILE" << METAEOF
{"pid": $$, "team": "$TEAM_NAME", "project": "$(pwd)", "spec": "$SPEC_NAME", "started": "$TIMESTAMP"}
METAEOF

# Run with agent teams enabled
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude --dangerously-skip-permissions "$(cat $PROMPT_FILE)"
