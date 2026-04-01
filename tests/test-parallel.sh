#!/usr/bin/env bash
# test-parallel.sh -- unit tests for scripts/lib/parallel.sh
# Validates dependency graph parsing, ready-task selection, and merge conflict handling.
#
# Usage:
#   ./tests/test-parallel.sh

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR=""

cleanup() {
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        # clean up any worktrees we created in the temp git repo
        if [[ -d "$TMP_DIR/repo" ]]; then
            cd "$TMP_DIR/repo"
            git worktree list --porcelain 2>/dev/null | grep "^worktree " | while read -r _ wt; do
                [[ "$wt" == "$TMP_DIR/repo" ]] && continue
                git worktree remove "$wt" --force 2>/dev/null || true
            done
            git worktree prune 2>/dev/null || true
        fi
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT

TMP_DIR="$(mktemp -d)"

# ── helpers ──────────────────────────────────────────────────

pass() { PASS=$((PASS + 1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }

assert_eq() {
    local actual="$1" expected="$2" label="$3"
    if [[ "$actual" == "$expected" ]]; then
        pass "$label"
    else
        fail "$label -- expected '$expected', got '$actual'"
    fi
}

assert_contains() {
    local haystack="$1" needle="$2" label="$3"
    if echo "$haystack" | grep -qF "$needle"; then
        pass "$label"
    else
        fail "$label -- '$needle' not found in output"
    fi
}

assert_not_contains() {
    local haystack="$1" needle="$2" label="$3"
    if echo "$haystack" | grep -qF "$needle"; then
        fail "$label -- '$needle' unexpectedly found in output"
    else
        pass "$label"
    fi
}

assert_file_contains() {
    local file="$1" pattern="$2" label="$3"
    if grep -qE "$pattern" "$file"; then
        pass "$label"
    else
        fail "$label -- pattern '$pattern' not in $file"
    fi
}

# ── source the library under test ────────────────────────────

source "$REPO_ROOT/scripts/lib/parallel.sh"

# ── build sample tasks.md ────────────────────────────────────
# 5 tasks with mixed dependencies:
#   T-1: no deps (completed)
#   T-2: depends on T-1 (pending)
#   T-3: no deps (pending)
#   T-4: depends on T-2 (pending)
#   T-5: depends on T-1, T-3 (pending)

create_sample_tasks() {
    local dest="$1"
    cat > "$dest" <<'TASKS_EOF'
# Tasks: test-feature

## Summary

| Status | Count |
|--------|-------|
| Pending | 4 |
| Completed | 1 |

---

## Phase 1: Setup

### T-1: First task

- **Status**: completed
- **Wired**: n/a
- **Verified**: yes
- **Requirements**: US-1
- **Description**: The first task to do.
- **Acceptance**: Something works.
- **Dependencies**: none

### T-2: Second task depends on T-1

- **Status**: pending
- **Wired**: no
- **Verified**: no
- **Requirements**: US-1
- **Description**: Depends on the first task.
- **Acceptance**: Something else works.
- **Dependencies**: T-1

### T-3: Third task no deps

- **Status**: pending
- **Wired**: no
- **Verified**: no
- **Requirements**: US-2
- **Description**: Independent task.
- **Acceptance**: Independent thing works.
- **Dependencies**: none

### T-4: Fourth task depends on T-2

- **Status**: pending
- **Wired**: no
- **Verified**: no
- **Requirements**: US-2
- **Description**: Depends on second task.
- **Acceptance**: Chain works.
- **Dependencies**: T-2

### T-5: Fifth task depends on T-1 and T-3

- **Status**: pending
- **Wired**: no
- **Verified**: no
- **Requirements**: US-3
- **Description**: Multi-dependency task.
- **Acceptance**: Both deps satisfied.
- **Dependencies**: T-1, T-3
TASKS_EOF
}

# ══════════════════════════════════════════════════════════════
echo "=== Test 1: parse_dependency_graph ==="
# Verify each task appears on one output line with correct deps
# ══════════════════════════════════════════════════════════════

TASKS_1="$TMP_DIR/tasks1.md"
create_sample_tasks "$TASKS_1"

GRAPH_OUTPUT=$(parse_dependency_graph "$TASKS_1")

# should have 5 lines, one per task
LINE_COUNT=$(echo "$GRAPH_OUTPUT" | wc -l | tr -d ' ')
assert_eq "$LINE_COUNT" "5" "parse_dependency_graph outputs 5 lines for 5 tasks"

# check each task's dependency listing
assert_contains "$GRAPH_OUTPUT" "T-1:none" "T-1 has no dependencies"
assert_contains "$GRAPH_OUTPUT" "T-2:T-1" "T-2 depends on T-1"
assert_contains "$GRAPH_OUTPUT" "T-3:none" "T-3 has no dependencies"
assert_contains "$GRAPH_OUTPUT" "T-4:T-2" "T-4 depends on T-2"
assert_contains "$GRAPH_OUTPUT" "T-5:T-1,T-3" "T-5 depends on T-1 and T-3"

# ══════════════════════════════════════════════════════════════
echo ""
echo "=== Test 2: get_ready_tasks (initial state) ==="
# T-1 completed, T-2 depends on T-1 (met), T-3 no deps (ready),
# T-4 depends on T-2 (pending, not met), T-5 depends on T-1+T-3 (T-3 pending)
# Expected ready: T-2, T-3
# ══════════════════════════════════════════════════════════════

TASKS_2="$TMP_DIR/tasks2.md"
create_sample_tasks "$TASKS_2"

READY=$(get_ready_tasks "$TASKS_2")

assert_contains "$READY" "T-2" "T-2 is ready (dep T-1 is completed)"
assert_contains "$READY" "T-3" "T-3 is ready (no deps)"
assert_not_contains "$READY" "T-4" "T-4 is NOT ready (dep T-2 still pending)"
assert_not_contains "$READY" "T-5" "T-5 is NOT ready (dep T-3 still pending)"
assert_not_contains "$READY" "T-1" "T-1 is NOT listed (already completed)"

# ══════════════════════════════════════════════════════════════
echo ""
echo "=== Test 3: get_ready_tasks (after T-2 and T-3 complete) ==="
# Mark T-2 and T-3 as completed. Now:
#   T-4 depends on T-2 (completed) -> ready
#   T-5 depends on T-1 (completed) + T-3 (completed) -> ready
# ══════════════════════════════════════════════════════════════

TASKS_3="$TMP_DIR/tasks3.md"
create_sample_tasks "$TASKS_3"

# use _set_task_status from parallel.sh to mark T-2 and T-3 completed
_set_task_status "$TASKS_3" "T-2" "completed"
_set_task_status "$TASKS_3" "T-3" "completed"

READY_2=$(get_ready_tasks "$TASKS_3")

assert_contains "$READY_2" "T-4" "T-4 is ready after T-2 completed"
assert_contains "$READY_2" "T-5" "T-5 is ready after T-1 and T-3 completed"
assert_not_contains "$READY_2" "T-1" "T-1 not listed (already completed)"
assert_not_contains "$READY_2" "T-2" "T-2 not listed (already completed)"
assert_not_contains "$READY_2" "T-3" "T-3 not listed (already completed)"

# ══════════════════════════════════════════════════════════════
echo ""
echo "=== Test 4: consolidate_parallel_results (merge conflict) ==="
# Create a real git repo with divergent branches that conflict,
# then verify consolidate re-queues the conflicting task.
# ══════════════════════════════════════════════════════════════

# set up a temp git repo
REPO_DIR="$TMP_DIR/repo"
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"

git init -q
git config user.email "test@test.com"
git config user.name "Test"

# create initial commit with a shared file
echo "line 1" > shared.txt
git add shared.txt
git commit -q -m "initial commit"

MAIN_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# set up a spec directory with tasks.md and progress.md
SPEC_DIR="$REPO_DIR/.claude/specs/test-feature"
mkdir -p "$SPEC_DIR"
create_sample_tasks "$SPEC_DIR/tasks.md"
touch "$SPEC_DIR/progress.md"
git add .claude
git commit -q -m "add spec files"

# create branch for task A -- modifies shared.txt line 1
BRANCH_A="spec/test-feature-t-2"
git checkout -q -b "$BRANCH_A"
echo "modified by task A" > shared.txt
git add shared.txt
git commit -q -m "task A changes"

# go back to main and create branch for task B -- also modifies shared.txt line 1
git checkout -q "$MAIN_BRANCH"
BRANCH_B="spec/test-feature-t-3"
git checkout -q -b "$BRANCH_B"
echo "modified by task B" > shared.txt
git add shared.txt
git commit -q -m "task B changes"

# go back to main for consolidation
git checkout -q "$MAIN_BRANCH"

# mark T-2 and T-3 as completed in tasks.md (simulating successful parallel execution)
_set_task_status "$SPEC_DIR/tasks.md" "T-2" "completed"
_set_task_status "$SPEC_DIR/tasks.md" "T-3" "completed"

# consolidate: T-2 should merge cleanly, T-3 should conflict
consolidate_parallel_results "$SPEC_DIR" "T-2 T-3" "$REPO_DIR" 2>/dev/null || true

# T-2 should have merged (its branch goes in first)
MERGED_CONTENT=$(cat shared.txt)
assert_eq "$MERGED_CONTENT" "modified by task A" "T-2 branch merged successfully"

# T-3 should be re-queued to pending (conflict)
T3_STATUS=$(_get_task_status "$SPEC_DIR/tasks.md" "T-3")
assert_eq "$T3_STATUS" "pending" "T-3 re-queued to pending after merge conflict"

# progress.md should log the conflict
assert_file_contains "$SPEC_DIR/progress.md" "Merge Conflict: T-3" "Conflict logged in progress.md"
assert_file_contains "$SPEC_DIR/progress.md" "Re-queued.*attempt 1" "Re-queue attempt count logged"

# requeue count should be 1
REQUEUE=$(_get_requeue_count "$SPEC_DIR/tasks.md" "T-3")
assert_eq "$REQUEUE" "1" "T-3 requeue count is 1"

# go back to repo root so cleanup works
cd "$TMP_DIR"

# ══════════════════════════════════════════════════════════════
echo ""
echo "=== Test 5: _get_task_status and _set_task_status ==="
# Verify internal helpers work correctly
# ══════════════════════════════════════════════════════════════

TASKS_5="$TMP_DIR/tasks5.md"
create_sample_tasks "$TASKS_5"

STATUS_T1=$(_get_task_status "$TASKS_5" "T-1")
assert_eq "$STATUS_T1" "completed" "_get_task_status reads T-1 as completed"

STATUS_T4=$(_get_task_status "$TASKS_5" "T-4")
assert_eq "$STATUS_T4" "pending" "_get_task_status reads T-4 as pending"

_set_task_status "$TASKS_5" "T-4" "in_progress"
STATUS_T4_NEW=$(_get_task_status "$TASKS_5" "T-4")
assert_eq "$STATUS_T4_NEW" "in_progress" "_set_task_status updates T-4 to in_progress"

# verify other tasks weren't affected
STATUS_T3_CHECK=$(_get_task_status "$TASKS_5" "T-3")
assert_eq "$STATUS_T3_CHECK" "pending" "T-3 status unchanged after T-4 update"

# ══════════════════════════════════════════════════════════════
echo ""
echo "=== Test 6: _get_requeue_count and _set_requeue_count ==="
# Verify requeue tracking helpers
# ══════════════════════════════════════════════════════════════

TASKS_6="$TMP_DIR/tasks6.md"
create_sample_tasks "$TASKS_6"

# initial count should be 0
COUNT_INIT=$(_get_requeue_count "$TASKS_6" "T-2")
assert_eq "$COUNT_INIT" "0" "Initial requeue count is 0"

# set and read back
_set_requeue_count "$TASKS_6" "T-2" "2"
COUNT_SET=$(_get_requeue_count "$TASKS_6" "T-2")
assert_eq "$COUNT_SET" "2" "Requeue count updated to 2"

# update existing count
_set_requeue_count "$TASKS_6" "T-2" "3"
COUNT_UPDATE=$(_get_requeue_count "$TASKS_6" "T-2")
assert_eq "$COUNT_UPDATE" "3" "Requeue count updated to 3"

# ══════════════════════════════════════════════════════════════
echo ""
echo "─────────────────────────────────────────"
echo "Results: $PASS passed, $FAIL failed"
echo "─────────────────────────────────────────"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
