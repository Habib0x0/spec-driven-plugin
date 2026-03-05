#!/bin/bash
set -e

SPEC_NAME=""
SCOPE="full"

# parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --spec-name)
      SPEC_NAME="$2"
      shift 2
      ;;
    --scope)
      SCOPE="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: spec-accept.sh [--spec-name <name>] [--scope <full|nonfunctional>]"
      echo ""
      echo "Options:"
      echo "  --spec-name    Spec name (auto-detected if only one exists)"
      echo "  --scope        Testing scope: full (default), nonfunctional"
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

# build prompt
PROMPT_FILE=$(mktemp)
trap "rm -f $PROMPT_FILE" EXIT

{
  echo "# User Acceptance Testing: $SPEC_NAME"
  echo ""
  echo "## Scope: $SCOPE"
  echo ""
  echo "## Requirements"
  cat "$SPEC_DIR/requirements.md"
  echo ""
  echo "## Design"
  cat "$SPEC_DIR/design.md"
  echo ""
  echo "## Tasks"
  cat "$SPEC_DIR/tasks.md"
  if [ -f "$SPEC_DIR/progress.md" ]; then
    echo ""
    echo "## Progress Log"
    cat "$SPEC_DIR/progress.md"
  fi
  cat << 'EOF'

## Instructions

You are performing **User Acceptance Testing (UAT)** — verifying that the implementation satisfies all spec requirements. This is NOT unit testing; you're checking that the RIGHT THING was built.

### Step 1: Get Your Bearings
1. Run `pwd` to see where you are.
2. Read the spec files above carefully — especially the acceptance criteria in requirements.md.
3. Check tasks.md to understand what was implemented.
4. If init.sh exists in the spec directory, read it to understand how to run the app.
5. Start the dev server if needed.

### Step 2: Build Acceptance Matrix
For each user story in requirements.md, list every EARS acceptance criterion:
- WHEN [trigger] THE SYSTEM SHALL [behavior]

### Step 3: Verify Each Criterion
For each acceptance criterion:

**UI behaviors** — Use Playwright MCP to:
- Navigate to the relevant page
- Perform the trigger action
- Verify the expected behavior
- Take screenshots as evidence

**API/logic behaviors** — Use curl or code inspection to:
- Hit the endpoint or invoke the function
- Verify the response matches the criterion

**Non-functional requirements** — Check:
- Performance: obvious bottlenecks, missing indexes
- Security: auth checks, input validation, data protection
- Accessibility: semantic HTML, ARIA labels

### Step 4: Classify Results
For each criterion:
- **PASS** — Behavior matches with evidence
- **FAIL** — Behavior doesn't match or is missing
- **PARTIAL** — Some aspects work, others don't
- **UNTESTABLE** — Cannot verify automatically (explain why)

### Step 5: Write Report
Write the UAT report to the spec directory as `acceptance.md`:

```markdown
## User Acceptance Test Report: [feature-name]

### Summary
- Total Acceptance Criteria: X
- Passed: X
- Failed: X
- Partial: X
- Untestable: X
- **Overall: ACCEPTED / NOT ACCEPTED**

### Results by Requirement
[Detailed results per requirement with evidence]

### Failed Criteria Details
[For each failure: expected, actual, likely cause, suggested fix]

### Non-Functional Requirements
[Performance, Security, Accessibility status]

### Recommendation
[ACCEPT or REJECT with reasoning]
```

### Step 6: Signal Result
- If ALL testable criteria PASS: output <promise>ACCEPTED</promise>
- If ANY criteria FAIL: output <promise>REJECTED</promise>

CRITICAL RULES:
- Test against the ACTUAL running application, not just code inspection.
- Provide evidence (screenshots, curl output) for every result.
- Do NOT modify any application code — this is read-only verification.
- Be thorough but practical — test what matters.
EOF
} > "$PROMPT_FILE"

echo "=== Running acceptance testing for: $SPEC_NAME (scope: $SCOPE) ==="
claude --dangerously-skip-permissions "$(cat $PROMPT_FILE)"
