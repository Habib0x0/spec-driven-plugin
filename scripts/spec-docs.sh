#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/spec-root.sh"
source "$SCRIPT_DIR/lib/agent-runner.sh"
source "$SCRIPT_DIR/lib/detect-backend.sh"
SPEC_ROOT="$(detect_spec_root)"


SPEC_NAME=""
OUTPUT_DIR=""

# parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --spec-name)
      SPEC_NAME="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: spec-docs.sh [--spec-name <name>] [--output-dir <path>]"
      echo ""
      echo "Options:"
      echo "  --spec-name    Spec name (auto-detected if only one exists)"
      echo "  --output-dir   Output directory (default: ${SPEC_ROOT}/<name>/docs/)"
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

# default output dir
if [ -z "$OUTPUT_DIR" ]; then
  OUTPUT_DIR="$SPEC_DIR/docs"
fi

mkdir -p "$OUTPUT_DIR"

# build prompt
PROMPT_FILE=$(mktemp)
trap "rm -f $PROMPT_FILE" EXIT

{
  echo "# Documentation Generation: $SPEC_NAME"
  echo ""
  echo "## Output Directory: $OUTPUT_DIR"
  echo ""
  echo "## Requirements"
  cat "$SPEC_DIR/requirements.md"
  echo ""
  echo "## Design"
  cat "$SPEC_DIR/design.md"
  echo ""
  echo "## Tasks"
  cat "$SPEC_DIR/tasks.md"
  cat << 'EOF'

## Instructions

You are a **Technical Writer** generating user-facing documentation from spec files and implemented code.

### Step 1: Analyze the Feature
1. Read the spec files above to understand what was built.
2. Scan the actual implementation code to get accurate signatures, types, and behaviors.
3. Determine the feature type (API, UI, full-stack, library, infrastructure).

### Step 2: Generate Documentation
Based on the feature type, generate the appropriate documents:

**For API/Backend features:**
- `api-reference.md` — Endpoints, request/response schemas, examples from actual code
- `adr.md` — Architecture Decision Record from design.md alternatives

**For UI/Frontend features:**
- `user-guide.md` — Step-by-step workflows derived from user stories
- Component reference if applicable

**For Full-Stack features:**
- All of the above

**For Infrastructure features:**
- `runbook.md` — Dependencies, configuration, health checks, rollback procedures
- `adr.md` — Architecture Decision Record

### Step 3: Quality Checks
Before finishing:
- Verify all code references point to actual files
- Verify API signatures match real implementation (not just design)
- Include realistic examples
- Only document completed features (check tasks.md status)

### Output
Write all documentation files to the output directory specified above.

### Completion
When all documents are written, output <promise>DOCS_GENERATED</promise>

CRITICAL RULES:
- Use actual code as source of truth, design.md as the guide.
- Write for the audience: user guides are non-technical, API refs are precise.
- Include examples everywhere.
- Flag any discrepancies between design.md and actual implementation.
- Do NOT document features that aren't implemented yet.
EOF
} > "$PROMPT_FILE"

echo "=== Generating documentation for: $SPEC_NAME ==="
echo "Output: $OUTPUT_DIR"
run_agent_prompt_file "$PROMPT_FILE"
