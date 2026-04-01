# Validate-Fix Loop Tests

Manual test checklist for the auto-validate-fix loop in `/spec` command (Step 4.5).

These tests verify that the validate-fix loop correctly catches spec issues, routes
fixes to the right agent, and exits cleanly when specs pass validation.

---

## Prerequisites

- Claude Code with spec-driven plugin installed
- A project directory with writable `.claude/specs/`
- The `/spec` command available

---

## Test 1: Clean spec passes on first cycle (early exit)

**Purpose**: Verify the loop does not waste cycles when there are no issues.

**Steps**:
1. Run `/spec test-clean-spec` on a simple, well-defined feature
2. During requirements gathering, provide clear, specific requirements with proper EARS notation:
   - Example: "WHEN a user clicks the save button THE SYSTEM SHALL persist the form data to the database"
3. Let the planner and tasker complete
4. Observe the summary output

**Expected**:
- [ ] Summary displays `Spec validated: PASS`
- [ ] The validator runs exactly once (check Claude output for a single validator invocation, not multiple)
- [ ] No fix agents are invoked (no spec-planner or spec-tasker re-invocations after the tasker phase)
- [ ] Total /spec execution does not include unnecessary re-validation cycles

**Pass criteria**: Summary shows PASS and only one validator cycle ran.

---

## Test 2: Vague requirement triggers fix cycle

**Purpose**: Verify that a known spec issue (vague term in acceptance criteria) is caught and fixed.

**Reproducible issue**: Intentionally use the vague term "quickly" in a requirement, which the
spec-validator flags as a violation of EARS notation rules.

**Steps**:
1. Run `/spec test-vague-fix` on a feature
2. During requirements gathering, include a deliberately vague acceptance criterion:
   - "WHEN the user submits the form THE SYSTEM SHALL respond quickly"
   - (The word "quickly" is vague -- validator should flag it)
3. Let the planner write requirements including this vague criterion
4. Let the tasker complete
5. Observe the validate-fix loop behavior

**Expected**:
- [ ] Validator detects the vague term "quickly" and reports a warning or error
- [ ] The loop routes the issue to `spec-planner` (since it is a requirements issue, not a task issue)
- [ ] The fix prompt includes the instruction "Fix ONLY the specific issues listed"
- [ ] After the planner fix, the validator re-runs
- [ ] The vague term is replaced with a measurable criterion (e.g., "within 2 seconds")
- [ ] Summary displays `Spec validated: PASS` (issue resolved within 3 cycles)

**Pass criteria**: Vague term caught, routed to planner, fixed, re-validated as PASS.

---

## Test 3: Task traceability gap triggers tasker fix

**Purpose**: Verify that task-level issues are routed to the spec-tasker (not the planner).

**Reproducible issue**: If the planner creates a requirement (e.g., US-3) but the tasker
produces tasks that reference only US-1 and US-2, the validator should flag the missing
traceability for US-3.

**Steps**:
1. Run `/spec test-trace-gap`
2. During requirements gathering, provide 3 distinct user stories
3. After the tasker completes, manually edit `.claude/specs/test-trace-gap/tasks.md` to
   remove all `US-3` references from task Requirements fields (simulating the gap)
4. If the loop has already run, manually re-trigger by running `/spec-validate` first to
   confirm the issue exists, then re-run `/spec test-trace-gap` with the same inputs
5. Observe the validate-fix loop

**Expected**:
- [ ] Validator detects that US-3 has no corresponding tasks
- [ ] The loop routes the fix to `spec-tasker` (task traceability is a task issue)
- [ ] The fix prompt includes the instruction "Fix ONLY the specific issues listed"
- [ ] After the tasker fix, tasks referencing US-3 are added
- [ ] Re-validation passes

**Pass criteria**: Missing traceability caught, routed to tasker, fixed within 3 cycles.

---

## Test 4: Mixed issues fix requirements before tasks

**Purpose**: Verify that when both requirement/design issues and task issues exist, the loop
fixes requirements first (since tasks depend on correct requirements).

**Steps**:
1. Run `/spec test-mixed-issues`
2. Provide requirements with one vague term AND ensure one user story has no tasks
3. Observe the validate-fix loop order

**Expected**:
- [ ] Validator reports both requirement issues (vague term) and task issues (missing traceability)
- [ ] The loop invokes `spec-planner` first to fix the requirement issue
- [ ] After requirements are fixed, the loop invokes `spec-tasker` to fix the task issue
- [ ] Requirement fix happens before task fix (not simultaneously or in reverse order)
- [ ] Re-validation passes after both fixes

**Pass criteria**: Fix ordering is requirements-first, then tasks, then re-validate.

---

## Test 5: Persistent issues cap at 3 cycles

**Purpose**: Verify the loop does not run indefinitely when issues cannot be resolved.

**Steps**:
1. Run `/spec test-persistent-issue`
2. Provide requirements that are intentionally difficult for the validator to accept
   (e.g., a complex domain-specific term that the validator repeatedly flags as vague
   but the planner keeps restating differently without satisfying the validator)
3. Alternatively, after each fix cycle manually reintroduce the issue by editing the
   requirements file to force the loop to exhaust its retries
4. Observe the loop behavior after 3 cycles

**Expected**:
- [ ] The loop runs exactly 3 cycles (not 2, not 4)
- [ ] After cycle 3, the loop exits even though issues remain
- [ ] Summary displays a message like "X errors and Y warnings remaining after 3 validation cycles"
- [ ] Summary suggests running `/spec-validate` manually to review remaining issues
- [ ] The spec files are still in a usable state (not corrupted by partial fixes)

**Pass criteria**: Loop caps at 3 cycles, summary shows remaining issue count, no crash.

---

## Test 6: Validation status appears in summary

**Purpose**: Verify the summary always includes validation status regardless of outcome.

**Steps**:
1. Run `/spec` on two features:
   - One that passes validation cleanly (see Test 1)
   - One that has remaining issues after 3 cycles (see Test 5)
2. Compare both summaries

**Expected**:
- [ ] Clean spec summary includes `Spec validated: PASS`
- [ ] Failing spec summary includes the remaining issue count string
- [ ] Both summaries include the standard fields (user stories count, tasks count, architecture decisions)
- [ ] Clean spec summary suggests `/spec-exec` or `/spec-loop`
- [ ] Failing spec summary suggests `/spec-validate` for manual review

**Pass criteria**: Validation status is always present in the summary output.

---

## Notes

- Tests 2 and 3 describe specific reproducible issues. If the planner or tasker have
  improved enough to never produce these issues, manually introduce them by editing
  the spec files between the tasker phase and the validation phase.
- The validate-fix loop is part of the `/spec` command workflow. It cannot be tested
  in isolation without running the full command.
- For automated CI, these tests would need to be wrapped in a script that drives
  Claude Code with predetermined inputs, which is outside the scope of this checklist.
