#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/spec-root.sh"
source "$SCRIPT_DIR/lib/agent-runner.sh"
source "$SCRIPT_DIR/lib/detect-backend.sh"
SPEC_ROOT="$(detect_spec_root)"


SPEC_NAME=""
TARGET_URL=""
SCOPE="full"

# parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --spec-name)
      SPEC_NAME="$2"
      shift 2
      ;;
    --url)
      TARGET_URL="$2"
      shift 2
      ;;
    --scope)
      SCOPE="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: spec-verify.sh --url <target-url> [--spec-name <name>] [--scope <full|quick>]"
      echo ""
      echo "Options:"
      echo "  --url          Target environment URL (required)"
      echo "  --spec-name    Spec name (auto-detected if only one exists)"
      echo "  --scope        Testing scope: full (default), quick (health check only)"
      exit 1
      ;;
  esac
done

# url is required
if [ -z "$TARGET_URL" ]; then
  echo "Error: --url is required."
  echo "Usage: spec-verify.sh --url <target-url> [--spec-name <name>] [--scope <full|quick>]"
  exit 1
fi

# auto-detect spec if not provided
if [ -z "$SPEC_NAME" ]; then
  if [ ! -d "$SPEC_ROOT" ]; then
    echo "Error: No specs directory found at $SPEC_ROOT."
    echo "Run /spec <name> first to create a spec."
    exit 1
  fi

  SPECS=()
  while IFS= read -r _spec; do
    [ -n "$_spec" ] && SPECS+=("$_spec")
  done < <(list_specs "$SPEC_ROOT")

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
OUTPUT_FILE=$(mktemp)
trap "rm -f $PROMPT_FILE $OUTPUT_FILE" EXIT

{
  echo "# Post-Deployment Verification: $SPEC_NAME"
  echo ""
  echo "## Target URL: $TARGET_URL"
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
  cat << EOF

## Instructions

You are running **post-deployment smoke tests** against a live environment to verify the feature works in production/staging.

**Target URL**: $TARGET_URL
**Scope**: $SCOPE

### Step 1: Health Check
1. Verify the target URL responds (curl or Playwright navigate).
2. Check the HTTP status code is 200.
3. If the app doesn't load, report immediately and stop.

### Step 2: Smoke Tests
EOF

  if [ "$SCOPE" = "quick" ]; then
    cat << 'EOF'
Quick scope — only verify:
- App loads at the target URL
- Key routes respond (check design.md for routes)
- No console errors or server errors
- Basic navigation works
EOF
  else
    cat << 'EOF'
Full scope — verify acceptance criteria that can be tested via browser/HTTP:

For each requirement in requirements.md:
1. Extract the EARS acceptance criteria
2. For browser-testable criteria: Use Playwright to navigate to the target URL and verify
3. For API criteria: Use curl against the target URL endpoints
4. Skip criteria requiring database manipulation or internal-only access

For each check, record:
- What was tested
- PASS or FAIL
- Evidence (screenshot, HTTP response)
EOF
  fi

  cat << EOF

### Step 3: Write Verification Report
Write (or append to) \`$SPEC_DIR/verification.md\`:

\`\`\`markdown
## Post-Deployment Verification

### Environment: $TARGET_URL
- Verified at: [timestamp]
- Scope: $SCOPE

### Results
| Check | Status | Details |
|-------|--------|---------|
| App loads | PASS/FAIL | [response time, status] |
| [Route/Feature 1] | PASS/FAIL | [details] |
| [Route/Feature 2] | PASS/FAIL | [details] |

### Summary
- Checks passed: X/Y
- Environment issues: [list any]
- **Verification: PASS / FAIL**
\`\`\`

### Completion
- If ALL checks PASS: output <promise>VERIFIED</promise>
- If ANY checks FAIL: output <promise>VERIFICATION_FAILED</promise>

CRITICAL RULES:
- Test against the TARGET URL, not localhost.
- Do NOT modify any code, data, or configuration.
- This is READ-ONLY verification.
- If the app doesn't load at all, that's an immediate FAIL — don't try to fix it.
- Take screenshots as evidence for every UI check.
- Report environment-specific issues (CORS, missing env vars, SSL) clearly.
EOF
} > "$PROMPT_FILE"

echo "=== Running post-deployment verification for: $SPEC_NAME ==="
echo "Target: $TARGET_URL"
echo "Scope: $SCOPE"
run_agent_prompt_file "$PROMPT_FILE" | tee "$OUTPUT_FILE"

# exit with appropriate code for CI/CD
if grep -q '<promise>VERIFIED</promise>' "$OUTPUT_FILE"; then
  echo ""
  echo "Verification PASSED"
  exit 0
elif grep -q '<promise>VERIFICATION_FAILED</promise>' "$OUTPUT_FILE"; then
  echo ""
  echo "Verification FAILED"
  exit 1
else
  echo ""
  echo "Verification INCONCLUSIVE — no promise marker found in output"
  exit 1
fi
