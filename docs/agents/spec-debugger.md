# spec-debugger

The spec-debugger is called when the tester or reviewer rejects an implementation. It brings a fresh perspective to a problem the implementer has already attempted to solve.

## Role

Fix the specific issues identified by the tester or reviewer, without rewriting code that isn't part of the problem.

## Model

**Sonnet.** Debugging at this stage is targeted and well-scoped — the failure report identifies what is broken, and the fix is usually a specific connection, logic correction, or security patch. Sonnet handles this efficiently.

## When It Runs

- `/spec-team` — dispatched by the Lead when the tester reports a verification failure
- `/spec-team` — dispatched by the Lead when the reviewer rejects an implementation
- Dispatched again if a previous fix attempt didn't resolve the issue

## What It Does

The debugger's first action is always to check wiring, regardless of the failure type. The most common reason code fails is that it exists but isn't connected to the application — a route not registered, a component not imported, an API endpoint not called from the frontend. The debugger walks a systematic chain:

```
Entry point -> Router -> Page component -> Navigation link
Page -> API call -> Registered endpoint -> Service -> Database
Response -> UI rendering
```

It finds the broken link and fixes it.

For functional failures, the debugger reads the tester's failure report, understands the root cause (not just the symptom), and fixes it. For review rejections, it addresses each issue listed by the reviewer — security fixes, refactoring, alignment with `design.md` — without introducing new problems in the process.

After fixing, the debugger traces the full path to confirm the correction is complete, then reports to the Lead that the task is ready for re-testing or re-review.

## Key Rules

- Checks wiring first, before investigating functional bugs — most failures are connection problems, not logic problems.
- Fixes only what was reported — no opportunistic rewrites.
- Does not argue with the tester or reviewer — addresses the issues they identified.
- If two fix attempts both fail, escalates to the Lead with a structured report: what was tried, root cause analysis, and a recommendation (modify the task, update the design, or mark as blocked).
