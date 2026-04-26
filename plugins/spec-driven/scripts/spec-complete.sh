#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/spec-root.sh"
source "$SCRIPT_DIR/lib/agent-runner.sh"
source "$SCRIPT_DIR/lib/detect-backend.sh"
SPEC_ROOT="$(detect_spec_root)"


SPEC_NAME=""
SKIP_ACCEPT=false
SKIP_DOCS=false
SKIP_RELEASE=false
SKIP_RETRO=false

# parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --spec-name)
      SPEC_NAME="$2"
      shift 2
      ;;
    --skip-accept)
      SKIP_ACCEPT=true
      shift
      ;;
    --skip-docs)
      SKIP_DOCS=true
      shift
      ;;
    --skip-release)
      SKIP_RELEASE=true
      shift
      ;;
    --skip-retro)
      SKIP_RETRO=true
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: spec-complete.sh [--spec-name <name>] [--skip-accept] [--skip-docs] [--skip-release] [--skip-retro]"
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

echo "============================================"
echo "  Post-Completion Pipeline: $SPEC_NAME"
echo "============================================"
echo ""
echo "Pipeline: accept -> docs -> release -> retro"
echo ""

PIPELINE_START=$(date +%s)
PIPELINE_STATUS="success"

run_step() {
  local step_name="$1"
  local script="$2"
  local promise="$3"
  shift 3
  local args=("$@")

  echo "--------------------------------------------"
  echo "  Step: $step_name"
  echo "--------------------------------------------"

  local step_start
  step_start=$(date +%s)

  local output_file
  output_file=$(mktemp)

  set +e
  bash "$SCRIPT_DIR/$script" --spec-name "$SPEC_NAME" "${args[@]}" 2>&1 | tee "$output_file"
  local exit_code=${PIPESTATUS[0]}
  set -e

  local step_end
  step_end=$(date +%s)
  local step_duration=$((step_end - step_start))

  if [ $exit_code -ne 0 ]; then
    echo ""
    echo "FAILED: $step_name exited with code $exit_code (${step_duration}s)"
    rm -f "$output_file"
    return 1
  fi

  if [ -n "$promise" ] && ! grep -q "<promise>${promise}</promise>" "$output_file"; then
    echo ""
    echo "FAILED: $step_name — expected promise <promise>${promise}</promise> not found (${step_duration}s)"
    rm -f "$output_file"
    return 1
  fi

  echo ""
  echo "PASSED: $step_name (${step_duration}s)"

  rm -f "$output_file"
  return 0
}

# Step 1: User Acceptance Testing
if [ "$SKIP_ACCEPT" = false ]; then
  if ! run_step "User Acceptance Testing" "spec-accept.sh" "ACCEPTED"; then
    # distinguish deliberate rejection from script crash
    if [ -f "$SPEC_DIR/acceptance.md" ] && grep -q "REJECTED" "$SPEC_DIR/acceptance.md"; then
      echo ""
      echo "Pipeline halted: Spec was REJECTED during UAT."
      echo "Fix the issues in acceptance.md and re-run."
      PIPELINE_STATUS="rejected"
    else
      echo ""
      echo "Pipeline halted: UAT failed."
      PIPELINE_STATUS="failed"
    fi
  fi
else
  echo "Skipping: User Acceptance Testing (--skip-accept)"
fi

# Step 2: Documentation
if [ "$PIPELINE_STATUS" = "success" ] && [ "$SKIP_DOCS" = false ]; then
  if ! run_step "Documentation Generation" "spec-docs.sh" "DOCS_GENERATED"; then
    echo "WARNING: Documentation generation failed, continuing pipeline..."
  fi
elif [ "$SKIP_DOCS" = true ]; then
  echo "Skipping: Documentation (--skip-docs)"
elif [ "$PIPELINE_STATUS" != "success" ]; then
  echo "Skipping: Documentation (pipeline status: $PIPELINE_STATUS)"
fi

# Step 3: Release
if [ "$PIPELINE_STATUS" = "success" ] && [ "$SKIP_RELEASE" = false ]; then
  if ! run_step "Release Notes" "spec-release.sh" "RELEASED"; then
    echo "WARNING: Release generation failed, continuing pipeline..."
  fi
elif [ "$SKIP_RELEASE" = true ]; then
  echo "Skipping: Release Notes (--skip-release)"
elif [ "$PIPELINE_STATUS" != "success" ]; then
  echo "Skipping: Release Notes (pipeline status: $PIPELINE_STATUS)"
fi

# Step 4: Retrospective
if [ "$PIPELINE_STATUS" = "success" ] && [ "$SKIP_RETRO" = false ]; then
  if ! run_step "Retrospective" "spec-retro.sh" "RETRO_COMPLETE"; then
    echo "WARNING: Retrospective failed, continuing pipeline..."
  fi
elif [ "$SKIP_RETRO" = true ]; then
  echo "Skipping: Retrospective (--skip-retro)"
elif [ "$PIPELINE_STATUS" != "success" ]; then
  echo "Skipping: Retrospective (pipeline status: $PIPELINE_STATUS)"
fi

PIPELINE_END=$(date +%s)
PIPELINE_DURATION=$((PIPELINE_END - PIPELINE_START))

echo ""
echo "============================================"
echo "  Pipeline Complete: $PIPELINE_STATUS (${PIPELINE_DURATION}s)"
echo "============================================"

if [ "$PIPELINE_STATUS" = "success" ]; then
  echo ""
  echo "Generated artifacts in $SPEC_DIR/:"
  [ -f "$SPEC_DIR/acceptance.md" ] && echo "  - acceptance.md"
  [ -d "$SPEC_DIR/docs" ] && echo "  - docs/"
  [ -f "$SPEC_DIR/release.md" ] && echo "  - release.md"
  [ -f "$SPEC_DIR/retro.md" ] && echo "  - retro.md"
  echo ""
  echo "<promise>PIPELINE_COMPLETE</promise>"
elif [ "$PIPELINE_STATUS" = "rejected" ]; then
  echo ""
  echo "Spec was rejected during UAT. Review acceptance.md for details."
  echo "<promise>PIPELINE_REJECTED</promise>"
  exit 1
else
  echo ""
  echo "Pipeline failed. Check output above for details."
  echo "<promise>PIPELINE_FAILED</promise>"
  exit 1
fi
