#!/bin/bash
set -e

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
      echo "Usage: spec-exec.sh [--spec-name <name>]"
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

# build prompt (same structure as ralph.sh)
PROMPT_FILE=$(mktemp)
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
  cat << 'EOF'

## Instructions
1. Find the highest-priority feature to work on and work only on that feature.
   This should be the one YOU decide has the highest priority - not necessarily the first in the list.
2. Check that the types check via pnpm typecheck and that the tests pass via pnpm test.
3. Update the SPEC with work that was done.
4. Append your progress to the tasks.md file.
   Use this to leave a note for the next person working in the codebase.
5. Make a git commit of that feature.

ONLY WORK ON A SINGLE FEATURE.
If, while implementing the feature, you notice the SPEC is complete, output <promise>COMPLETE</promise>.
EOF
} > "$PROMPT_FILE"

echo "=== Running spec-exec for: $SPEC_NAME ==="
claude --dangerously-skip-permissions "$(cat $PROMPT_FILE)"
