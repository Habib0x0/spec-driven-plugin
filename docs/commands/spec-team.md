# /spec-team

Run spec implementation with a coordinated team of specialized roles. Each task goes through implementation, testing, and review before being committed — providing stronger quality and security guarantees than single-agent execution.

## Usage

Run the script from your project root:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/spec-team.sh [--spec-name <name>] [--max-iterations <n>]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--spec-name <name>` | No | Which spec to execute against. Auto-detected if only one spec exists in `.claude/specs/`. |
| `--max-iterations <n>` | No | Maximum number of iterations before stopping. |

## What It Does

For each task, the team runs a pipeline with automatic retry on failure:

```
1. Implementer writes code
         |
2. Tester verifies (Playwright / test suite)
         |
   PASS  |  FAIL
         |---------> Debugger fixes --> back to step 2
         |
3. Reviewer checks code quality, security, architecture
         |
APPROVE  |  REJECT
         |---------> Debugger fixes --> back to step 2/3
         |
4. Commit
```

The cycle repeats for each pending task until all are complete or the iteration limit is reached.

## Prerequisites

- A completed spec in `.claude/specs/<name>/` with all three files.
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` — the script sets this automatically.
- Playwright MCP configured for UI testing (required for frontend features).

## When to Use `/spec-team` vs `/spec-loop`

Use `/spec-team` when:
- Tasks were being marked complete without real testing in single-agent mode
- The feature handles sensitive data or has security implications
- You need separation of concerns between the person who writes code and the person who tests it
- Code quality and architecture review before commit is a requirement

Use `/spec-loop` when:
- The feature is straightforward and well-defined
- Speed matters more than the additional review layer
- Token cost is a constraint

!!!note
    Agent teams use approximately 3-4x more tokens than single-agent mode because each role maintains its own context. Factor this into your decision.

## Tips

- After the team completes, run `/spec-sync` to bring the Claude Code task list up to date.
- The reviewer focuses on security, code quality, and architectural consistency — not just whether tests pass.
- If a task is rejected multiple times, it may indicate an ambiguity in the spec. Check `/spec-status` for patterns and consider running `/spec-refine`.

## See Also

- [/spec-loop](spec-loop.md) — Faster single-agent loop without review gates
- [/spec-exec](spec-exec.md) — Single-task execution with manual checkpoints
- [/spec-sync](spec-sync.md) — Sync task statuses after the team finishes
- [/spec-accept](spec-accept.md) — Formal acceptance testing after all tasks are complete
