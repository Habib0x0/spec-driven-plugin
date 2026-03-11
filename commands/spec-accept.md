---
name: spec-accept
description: Run user acceptance testing against spec requirements for formal sign-off
argument-hint: "[spec-name]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - AskUserQuestion
  - Task
---

# /spec-accept Command

Perform user acceptance testing (UAT) to verify the implementation satisfies all spec requirements. This bridges the gap between "code works" (spec-tester) and "the right thing was built" (acceptance).

## Philosophy

Automated tests verify correctness. Acceptance testing verifies **value**. The spec-tester checks that code passes tests per task; the spec-reviewer checks security and code quality; the acceptor verifies that every EARS acceptance criterion in `requirements.md` traces to verified, reviewed tasks and that non-functional requirements are met. This is the last gate before release.

The acceptor does NOT re-run functional or security tests — it reads results from `tasks.md` (tester verification) and references reviewer assessments. It focuses on traceability, non-functional gaps, and formal sign-off.

## Workflow

### 1. Locate the Spec

If a spec name is provided as an argument, use it. Otherwise:
- Check `.claude/specs/` for available specs
- If only one spec exists, use it automatically
- If multiple exist, ask the user which spec to accept via AskUserQuestion

### 2. Pre-flight Check

Read `tasks.md` and verify implementation status:
- If tasks are still incomplete, warn the user:
  *"X of Y tasks are still incomplete. Acceptance testing works best on completed features. Want to proceed anyway or finish implementation first?"*
- Use AskUserQuestion: "Proceed with partial testing" / "Finish implementation first"

### 3. Ask About Testing Scope

Use AskUserQuestion:
- **Full acceptance test** — Test all requirements and acceptance criteria
- **Specific requirements only** — Let me pick which requirements to test
- **Non-functional requirements only** — Focus on performance, accessibility, data integrity

If "Specific requirements only," follow up asking which requirement IDs to test.

### 4. Spawn the Acceptor Agent

Delegate to the **spec-driven:spec-acceptor** agent via the Task tool.

Pass the agent:
- The spec directory path (`.claude/specs/<feature-name>/`)
- The testing scope (full, specific IDs, or non-functional only)
- Any relevant context about how to run the app (if known from design.md or codebase)

### 5. Present Results

When the acceptor returns its UAT report:

1. **Summarize the results conversationally:**
   - *"Acceptance testing is complete. X of Y criteria passed."*
   - Highlight any failures or partial results

2. **For each failed criterion**, explain:
   - What was expected (from the requirement)
   - What actually happens
   - The acceptor's suggested fix

3. **Ask for the user's decision** via AskUserQuestion:
   - **Accept — ready to release** — Mark the spec as accepted, proceed to `/spec-release`
   - **Accept with conditions** — Note minor issues for post-release, proceed
   - **Reject — needs fixes** — List the failed criteria, suggest running `/spec-refine` to update requirements or fixing the implementation
   - **Re-test specific items** — Run the acceptor again on a subset

### 6. Record the Decision

Based on the user's decision:

- **Accepted**: Write acceptance status to `.claude/specs/<feature-name>/acceptance.md` with:
  - Date of acceptance
  - UAT report summary
  - Any conditions noted
  - User's sign-off decision

- **Rejected**: Note the rejection and failed criteria. Suggest next steps:
  - `/spec-refine` if requirements need updating
  - Fix implementation if requirements are correct but code doesn't match
  - Re-run `/spec-accept` after fixes

## Tips

- Run this after `/spec-team` or `/spec-loop` completes all tasks
- It's normal for some criteria to be UNTESTABLE automatically — the report will flag these for manual verification
- Non-functional requirements (performance, security, accessibility) are often overlooked — this catches them
- The acceptance report becomes part of the spec record, useful for audits and retrospectives
