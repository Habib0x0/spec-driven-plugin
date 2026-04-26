#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/spec-root.sh"
source "$SCRIPT_DIR/lib/agent-runner.sh"
source "$SCRIPT_DIR/lib/detect-backend.sh"
SPEC_ROOT="$(detect_spec_root)"


SPEC_NAME=""

# parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --spec-name)
      SPEC_NAME="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: spec-retro.sh [--spec-name <name>]"
      echo ""
      echo "Options:"
      echo "  --spec-name    Spec name (auto-detected if only one exists)"
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

# build prompt
PROMPT_FILE=$(mktemp)
trap "rm -f $PROMPT_FILE" EXIT

{
  echo "# Retrospective Analysis: $SPEC_NAME"
  echo ""
  echo "## Requirements"
  cat "$SPEC_DIR/requirements.md"
  echo ""
  echo "## Design"
  cat "$SPEC_DIR/design.md"
  echo ""
  echo "## Tasks"
  cat "$SPEC_DIR/tasks.md"
  echo ""
  if [ -f "$SPEC_DIR/progress.md" ]; then
    echo "## Progress Log"
    cat "$SPEC_DIR/progress.md"
  else
    echo "## Progress Log"
    echo "(progress.md not found — this spec did not maintain a progress log)"
  fi
  echo ""
  echo "## Git History (last 20 commits)"
  git log --oneline -20 2>/dev/null || echo "(git log unavailable)"
  echo ""
  cat << 'EOF'
## Instructions

You are generating a **retrospective** for the spec above. Analyze the development process and produce actionable insights.

### Step 1: Analyze Iteration Data
1. Read progress.md (if present) to count how many iterations/sessions were needed.
2. Identify debugging cycles — tasks that changed status multiple times or required multiple attempts.
3. Check the git log for commit patterns: fix-vs-feature ratio, commit frequency, time span.

### Step 2: Identify What Went Well
- Tasks that completed smoothly on the first attempt
- Design decisions that proved correct
- Patterns that should be repeated in future specs

### Step 3: Identify What Caused Friction
- Tasks that required multiple iterations or debugging
- Requirements that were ambiguous or changed
- Integration issues between components
- Tooling or environment problems

### Step 4: Root Cause Analysis
For each friction point, identify the root cause:
- Was the requirement unclear?
- Was the design incomplete?
- Was the task too large?
- Was there a missing dependency?

### Step 5: Generate Action Items
Concrete, actionable improvements for future specs:
- Process improvements
- Template or tooling changes
- Patterns to adopt or avoid

### Step 6: Write Report
Write the retrospective to the spec directory as `retro.md`:

```markdown
# Retrospective: [spec-name]

## Summary
- Total sessions/iterations: X
- Tasks completed: X/Y
- Time span: [first commit] to [last commit]
- Fix-to-feature commit ratio: X:Y

## What Went Well
[Bullet points]

## What Caused Friction
[Bullet points with specific examples]

## Root Cause Analysis
[Table or list mapping friction points to root causes]

## Action Items
[Numbered list of concrete improvements]

## Metrics
- Average tasks per session: X
- Tasks requiring debugging: X
- Requirements changes during implementation: X
```

### Step 7: Signal Completion
Output <promise>RETRO_COMPLETE</promise> when the retrospective is written.

CRITICAL RULES:
- Write retro.md to the spec directory.
- Be specific — reference actual task IDs, commit messages, and session numbers.
- Focus on actionable insights, not generic advice.
- If progress.md is missing, note this gap and work with available data (tasks.md status, git log).
- Do NOT modify any spec files — this is a read-only analysis.
EOF
} > "$PROMPT_FILE"

echo "=== Running retrospective for: $SPEC_NAME ==="
run_agent_prompt_file "$PROMPT_FILE"
