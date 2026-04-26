#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/spec-root.sh"
source "$SCRIPT_DIR/lib/agent-runner.sh"
source "$SCRIPT_DIR/lib/detect-backend.sh"
SPEC_ROOT="$(detect_spec_root)"


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

You are performing **User Acceptance Testing (UAT)** — verifying that the implementation satisfies all spec requirements. You do NOT re-run functional tests (the spec-tester already did that). You verify traceability, non-functional requirements, and formal acceptance.

### Step 1: Get Your Bearings
1. Run `pwd` to see where you are.
2. Read the spec files above carefully — especially the acceptance criteria in requirements.md.
3. Check tasks.md to understand what was implemented and which tasks are Verified: yes/no.

### Step 2: Build Traceability Matrix
For each user story in requirements.md, map every EARS acceptance criterion to implementing tasks:
- WHEN [trigger] THE SYSTEM SHALL [behavior] -> Implemented by: T-X (Verified: yes/no)

### Step 3: Verify Traceability
For each acceptance criterion:
- Is there at least one completed, verified task that implements it?
- Are there orphan tasks (tasks not linked to any requirement)?
- Are there unimplemented requirements (criteria with no task)?

Trust the spec-tester's functional verification (Verified: yes in tasks.md).
Trust the spec-reviewer's security assessment.

### Step 4: Verify Non-Functional Requirements
Focus on what the tester and reviewer don't cover:
- Performance: obvious bottlenecks, N+1 queries, missing indexes, unbounded queries
- Accessibility: semantic HTML, ARIA labels, keyboard navigation
- Data integrity: validation, constraints, transaction boundaries

Security is covered by the spec-reviewer — reference their results, don't re-check.

### Step 5: Classify Results
For each criterion:
- **PASS** — Traced to verified task(s), non-functional checks pass
- **FAIL** — No implementing task, task not verified, or non-functional issue
- **PARTIAL** — Some aspects covered, others missing
- **UNTESTABLE** — Cannot verify automatically (explain why)

### Step 6: Write Report
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

### Traceability Matrix
[Per requirement: AC -> implementing tasks -> verified status -> result]

### Gaps Found
[Unimplemented criteria, unverified tasks, orphan tasks]

### Non-Functional Requirements
[Performance, Accessibility, Data Integrity status]
[Security: reference spec-reviewer results]

### Recommendation
[ACCEPT or REJECT with reasoning]
```

### Step 7: Signal Result
- If ALL testable criteria PASS: output <promise>ACCEPTED</promise>
- If ANY criteria FAIL: output <promise>REJECTED</promise>

CRITICAL RULES:
- Do NOT re-run functional tests — read tester results from tasks.md.
- Do NOT re-check security — reference reviewer results.
- Focus on traceability gaps and non-functional requirements.
- Do NOT modify any application code — this is read-only verification.
- Be thorough but practical — test what matters.
EOF
} > "$PROMPT_FILE"

echo "=== Running acceptance testing for: $SPEC_NAME (scope: $SCOPE) ==="
run_agent_prompt_file "$PROMPT_FILE"
