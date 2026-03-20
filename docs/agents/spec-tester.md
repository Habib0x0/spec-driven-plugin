# spec-tester

The spec-tester is the quality gate in the implementation pipeline. It verifies that code works as a user would actually experience it — not just that it compiles, but that it is reachable, functional, and meets every acceptance criterion.

## Role

Verify implemented tasks end-to-end. The tester is the only agent that can mark a task `Verified: yes`.

## Model

**Sonnet.** Verification follows a clear protocol: check wiring, run tests, capture evidence, report results. Sonnet executes this reliably and has access to the Playwright MCP tools needed for browser testing.

## When It Runs

- `/spec-team` — invoked after the implementer reports a task complete
- Called back in when the debugger fixes an issue and requests re-verification

## What It Does

**Step 0 — Integration check (mandatory before any functional testing)**

The tester first confirms the code is reachable from the application's normal entry points. For UI features, this means navigating from the home page or dashboard through normal navigation links, not by directly entering a URL. For API features, this means confirming the endpoint is registered and callable from the frontend. If the integration check fails, testing stops immediately and the tester reports the specific wiring gap.

**Functional testing**

For UI features, the tester uses Playwright to navigate the app as a real user would, interact with elements, and verify expected behavior. Screenshots are taken as evidence. For API and backend features, the tester uses curl or the project's test suite.

Every acceptance criterion from the task must pass before the tester approves.

**Reporting**

On success: updates `tasks.md` with `Wired: yes` and `Verified: yes`, then reports to the Lead with a summary of what was tested and the evidence collected.

On failure: reports the failure type (integration, functional, or both), the specific acceptance criterion that failed, what was expected versus what actually happened, and a recommendation for whether the debugger or implementer should handle the fix.

## Key Rules

- Never marks `Verified: yes` without actually running tests.
- Never skips the integration check — a feature that works in isolation but cannot be reached is not considered verified.
- Always takes screenshots as evidence for UI features.
- Always reports specific error messages, not vague descriptions.
- Does not fix issues — reports them to the Lead, who dispatches the debugger.
