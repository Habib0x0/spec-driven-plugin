# spec-reviewer

The spec-reviewer examines code after the tester has confirmed it works. Its job is to catch the class of problems that functional testing misses: security vulnerabilities, architectural drift, subtle bugs, and maintainability concerns.

## Role

Review code quality, security, and architectural alignment. The reviewer is the only agent that can give final approval for a task to be committed.

## Model

**opus tier.** Security vulnerabilities and architectural issues are often subtle — an injection vector buried in an interpolated string, a race condition in an async flow, or an abstraction that looks right but violates the design's separation of concerns. Opus's deeper reasoning is warranted here because the cost of missing these issues is high.

## When It Runs

- Can be invoked directly via the Task tool for code review after implementation
- Called back in after the debugger addresses review feedback

## What It Does

The reviewer reads the task's acceptance criteria, the changed files, and `design.md`, then evaluates the implementation across four areas:

**Integration completeness** — Verifies that routes are registered, pages are linked in navigation, components are imported and rendered, and API endpoints are callable from the frontend. Even after the tester's integration check, the reviewer independently confirms the wiring is complete. Missing wiring is grounds for rejection.

**Security** — Checks for input validation, authentication and authorization enforcement, SQL injection, XSS, CSRF, sensitive data exposure, and error messages that leak implementation details.

**Code quality** — Evaluates whether the code follows existing project patterns, handles errors appropriately, avoids dead code, and has no obvious performance issues.

**Architecture** — Confirms the implementation matches `design.md` — proper separation of concerns, correct use of abstractions, and no shortcuts that create future problems.

**Subtle bugs** — Looks for race conditions, off-by-one errors, null/undefined handling gaps, and resource leaks that functional tests are unlikely to catch.

On approval, the reviewer reports the outcome to the Lead and the task proceeds to commit. On rejection, the reviewer provides specific, actionable feedback — file name, line reference, and how to fix it — and the Lead dispatches the debugger.

## Key Rules

- Reviews happen after the tester verifies, not before.
- Feedback must be specific: file, location, and a concrete fix — not general critique.
- The reviewer focuses on real issues, not style preferences.
- If the code is secure and correct, the reviewer approves without nitpicking.
- Does not modify code — only approves or rejects with feedback.
