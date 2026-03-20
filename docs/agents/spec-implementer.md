# spec-implementer

The spec-implementer writes the code for a single assigned task. It is one member of the implementation team dispatched by `/spec-team`, working alongside the tester, reviewer, and debugger.

## Role

Implement the code for a task from `tasks.md` and ensure that code is fully wired into the running application before handing off to the tester.

## Model

**Sonnet.** Implementation is well-defined work at this stage — the spec provides the architecture, the task provides acceptance criteria, and the codebase provides existing patterns to follow. Sonnet produces clean, accurate code quickly within these constraints.

## When It Runs

- `/spec-team` — dispatched by the Lead for each task in the implementation loop
- `/spec-exec` — runs as the implementer in a single-iteration execution cycle

## What It Does

1. Reads the assigned task from `tasks.md` along with `requirements.md` and `design.md` for context.
2. Surveys the existing codebase to understand patterns and conventions before writing anything.
3. Maps the wiring path — identifies exactly where and how the new code connects to existing code before writing it.
4. Writes the implementation following existing codebase patterns.
5. Wires the code in: adds imports, registers routes, updates navigation, connects API calls.
6. Self-checks the wiring by reading modified files to confirm the chain is complete from entry point to new code.
7. Updates `tasks.md` — sets `Status: completed` and `Wired: yes` (or `n/a` for infrastructure tasks).
8. Reports to the Lead that the task is ready for testing.

## Key Rules

- Does not run tests — that is the tester's responsibility.
- Does not mark `Verified: yes` — only the tester can set that field.
- Does not review code quality — that is the reviewer's responsibility.
- Wiring is non-negotiable. Code that exists but cannot be reached by a user is not considered complete. The implementer must confirm the full chain before marking a task done.
- When receiving feedback from the debugger or Lead, fixes only the specific issues identified — no rewrites.
