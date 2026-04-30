# Agents

The plugin uses 11 specialized agents, each optimized for a specific phase of the workflow. You don't invoke agents directly — they are automatically dispatched by commands like `/spec`, `/spec-brainstorm`, and the post-implementation commands.

## Model Routing

Each agent is assigned a model tier that best fits its task. Reasoning-heavy phases use the opus tier; structured, fast-output phases use the sonnet tier; lightweight fixes use the haiku tier. Claude Code resolves each tier alias to the current model at runtime, and every agent's tier can be overridden via `SPEC_MODEL_*` environment variables (see [model-routing](../advanced/model-routing.md)).

| Agent | Model Tier | Phase | Why |
|-------|------------|-------|-----|
| [spec-planner](spec-planner.md) | opus | Requirements + Design | Deep reasoning for edge cases, security, and architectural tradeoffs |
| [spec-tasker](spec-tasker.md) | sonnet | Task breakdown | Fast, structured decomposition from a completed design |
| [spec-validator](spec-validator.md) | sonnet | Validation | Checklist-based verification across all three spec documents |
| [spec-implementer](spec-implementer.md) | sonnet | Implementation | Writes code and wires it into the running application |
| [spec-tester](spec-tester.md) | sonnet | Testing | Verifies features end-to-end using Playwright and test suites |
| [spec-reviewer](spec-reviewer.md) | opus | Code review | Catches security issues, architectural drift, and subtle bugs |
| [spec-debugger](spec-debugger.md) | haiku | Debugging | Fixes issues identified by the Tester or Reviewer |
| [spec-consultant](spec-consultant.md) | sonnet | Brainstorm consultation | Domain expert analysis during `/spec-brainstorm` sessions |
| [spec-acceptor](spec-acceptor.md) | sonnet | Acceptance | Requirement traceability, non-functional verification, formal sign-off |
| [spec-documenter](spec-documenter.md) | sonnet | Documentation | Generates API refs, user guides, and ADRs from spec and code |
| [spec-scanner](spec-scanner.md) | sonnet | Profile scan | Detects framework, patterns, entities, and registration points |

## Agent Roles

### Planning pipeline

**[spec-planner](spec-planner.md)** runs during `/spec` to produce `requirements.md` and `design.md`. It uses opus tier to reason carefully about edge cases, security implications, and architectural tradeoffs before a single line of code is written.

**[spec-tasker](spec-tasker.md)** picks up after the planner and breaks the design into discrete, trackable tasks organized across five phases: Setup, Core Implementation, Integration, Testing, and Polish. It syncs tasks to Claude Code's todo system.

**[spec-validator](spec-validator.md)** checks the three spec documents for completeness and consistency. It verifies EARS notation, cross-document ID alignment, dependency graphs, and that every requirement has a corresponding task.

### Brainstorm pipeline

**[spec-consultant](spec-consultant.md)** is a parameterized agent spawned during `/spec-brainstorm` sessions. Each instance takes on a different expert persona (security, architecture, UX, etc.) and returns structured analysis specific to the codebase and discussion.

### Implementation pipeline

The core implementation loop runs in this order, primarily through `/spec-exec` or `spec-loop.sh`:

1. **[spec-implementer](spec-implementer.md)** — writes the code and wires it into the application
2. **[spec-tester](spec-tester.md)** — verifies the implementation works end-to-end; only this agent can mark a task `Verified: yes`
3. **[spec-reviewer](spec-reviewer.md)** — reviews code quality, security, and architectural alignment after the tester approves; only this agent can give final approval
4. **[spec-debugger](spec-debugger.md)** — called when the Tester or Reviewer rejects an implementation, bringing a fresh perspective to fix the specific issues

### Post-implementation pipeline

**[spec-acceptor](spec-acceptor.md)** runs after all tasks are complete. It maps every EARS acceptance criterion back to verified tasks to confirm the right thing was built, and produces a formal UAT report.

**[spec-documenter](spec-documenter.md)** generates user-facing documentation — API references, user guides, architecture decision records, and runbooks — from spec files and actual implementation code.

**[spec-scanner](spec-scanner.md)** runs during Phase 0 of `/spec` to build a project profile (`_project-profile.md`). It detects the framework, existing code patterns, domain entities, and the exact file/line registration points where new code must be wired. This profile is used by the implementer and verification gate to ensure new code is connected correctly.
