# spec-reviewer

The spec-reviewer examines code after the tester has confirmed it works. Its job is to catch the class of problems that functional testing misses: security vulnerabilities, architectural drift, subtle bugs, and maintainability concerns.

## Role

Review code quality, security, and architectural alignment. The reviewer is the only agent that can give final approval for a task to be committed.

## Model

**Reasoning tier.** Security vulnerabilities and architectural issues are often subtle — an injection vector buried in an interpolated string, a race condition in an async flow, or an abstraction that looks right but violates the design's separation of concerns. Deeper reasoning is warranted here because the cost of missing these issues is high.

## When It Runs

- Can be invoked directly via the Task tool for code review after implementation
- Called back in after the debugger addresses review feedback

## What It Does

The reviewer reads the task's acceptance criteria, the changed files, and `design.md`, then evaluates the implementation across four areas:
