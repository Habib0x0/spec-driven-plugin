#!/usr/bin/env bash
# lib/verify.sh — Verification gate utilities for registration point checks
# Provides run_verification_gate() and run_debugger_fix() for post-task wiring validation.
# Source this file; do not execute directly.

if ! declare -f run_agent_prompt >/dev/null 2>&1; then
  # shellcheck source=agent-runner.sh
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/agent-runner.sh"
fi

# run_verification_gate(spec_dir, task_id, work_dir)
# Reads the project profile and the task's changed files (via git diff).
# For each new file/export, checks if it appears at the expected registration points.
# Returns 0 if all checks pass, 1 if wiring gaps found.
# Outputs the gap description to stdout on failure.
run_verification_gate() {
  local spec_dir="$1"
  local task_id="$2"
  local work_dir="$3"

  # find the project profile
  local profile_path=""
  local specs_root
  specs_root="$(dirname "$spec_dir")"

  if [ -f "$specs_root/_project-profile.md" ]; then
    profile_path="$specs_root/_project-profile.md"
  elif [ -f "$specs_root/_profile-index.md" ]; then
    profile_path="$specs_root/_profile-index.md"
  else
    echo "No project profile -- verification gate skipped."
    return 0
  fi

  # extract the Registration Points section from the profile
  local reg_points
  reg_points=$(awk '/^## Registration Points/,/^## /' "$profile_path" | head -100)

  if [ -z "$reg_points" ]; then
    echo "No registration points in profile -- verification gate skipped."
    return 0
  fi

  # get the git diff for recent changes in the work dir
  local diff_output
  diff_output=$(git -C "$work_dir" diff HEAD~1 --name-status 2>/dev/null || git -C "$work_dir" diff --cached --name-status 2>/dev/null || echo "")

  if [ -z "$diff_output" ]; then
    echo "No diff detected -- verification gate skipped."
    return 0
  fi

  # build a verification prompt for the configured agent
  local prompt
  prompt=$(cat <<PROMPT_EOF
You are a wiring verification checker. Given the registration points from a project profile and a git diff, determine whether new files or exports are properly registered.

## Registration Points
$reg_points

## Git Diff (changed files)
$diff_output

## Task
$task_id

## Instructions
1. Look at the new/modified files in the diff.
2. For each new file that should be registered at a registration point (e.g., new route, new command, new component), check if the corresponding registration file was also modified in the diff.
3. If a new artifact was created but its registration point file was NOT modified, that is a WIRING GAP.
4. If all new artifacts are properly registered, or if the changes don't require registration, output exactly: GATE_PASS
5. If there are wiring gaps, output: GATE_FAIL followed by a description of each gap on separate lines.

Be concise. Only flag genuine wiring gaps where a new artifact clearly needs registration but wasn't registered.
PROMPT_EOF
)

  local gate_output
  gate_output=$(run_agent_prompt "$prompt" 2>/dev/null)
  local agent_exit=$?

  if [ $agent_exit -ne 0 ]; then
    echo "Verification gate: agent invocation failed (exit $agent_exit) -- skipping gate."
    return 0
  fi

  if echo "$gate_output" | grep -q "GATE_PASS"; then
    return 0
  fi

  # extract the gap description (everything after GATE_FAIL)
  local gap_desc
  gap_desc=$(echo "$gate_output" | sed -n '/GATE_FAIL/,$ p' | tail -n +2)
  if [ -z "$gap_desc" ]; then
    gap_desc="$gate_output"
  fi

  echo "$gap_desc"
  return 1
}

# run_debugger_fix(spec_dir, task_id, gap_description, work_dir)
# Spawns the configured agent with a debugger prompt to fix a specific wiring gap.
# Returns 0 if fix was applied, 1 if debugger failed.
run_debugger_fix() {
  local spec_dir="$1"
  local task_id="$2"
  local gap_description="$3"
  local work_dir="$4"

  local prompt
  prompt=$(cat <<PROMPT_EOF
You are a wiring debugger. A verification gate detected a wiring gap after task $task_id was implemented.

## Wiring Gap
$gap_description

## Instructions
1. Read the files mentioned in the gap description.
2. Identify the exact registration point where the new artifact should be wired in.
3. Make the minimal edit to register/wire the new artifact.
4. Do NOT refactor or change anything beyond the specific wiring fix.
5. After fixing, output: FIX_APPLIED

Working directory: $work_dir
Spec directory: $spec_dir
PROMPT_EOF
)

  local fix_output
  fix_output=$(cd "$work_dir" && run_agent_prompt "$prompt" 2>/dev/null)
  local agent_exit=$?

  if [ $agent_exit -ne 0 ]; then
    echo "Debugger fix: agent invocation failed (exit $agent_exit)." >&2
    return 1
  fi

  if echo "$fix_output" | grep -q "FIX_APPLIED"; then
    return 0
  fi

  return 1
}
