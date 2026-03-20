# Workflow overview

The full spec-driven lifecycle moves from idea to deployed feature through six stages:

```
Brainstorm -> Requirements -> Design -> Tasks -> Execution -> Post-Implementation
```

Each stage has dedicated commands and produces artifacts that feed the next stage.

## Stage 0: Brainstorm (optional)

Use `/spec-brainstorm` when you have a vague idea that needs refinement before formalizing. This is a free-form conversation — no structured output yet.

When the idea is solid, brainstorm outputs a brief that you paste as context for `/spec`.

See [Brainstorming](brainstorming.md).

## Stage 1: Requirements

`/spec <feature-name>` starts the three-phase workflow. The spec-planner agent (Opus) guides you through:

- Identifying user roles and their goals
- Writing user stories in standard format
- Capturing acceptance criteria using EARS notation
- Documenting non-functional requirements, out-of-scope items, and open questions

Output: `requirements.md`

See [Requirements](requirements.md).

## Stage 2: Design

Immediately after requirements, the spec-planner continues into the design phase:

- Architecture overview and component diagram
- Data flow between components
- Data models and type definitions
- API endpoint specifications
- Sequence diagrams for key interactions
- Security and performance considerations

Output: `design.md`

See [Design](design.md).

## Stage 3: Tasks

The spec-tasker agent (Sonnet) breaks the design into discrete, trackable tasks:

- Five phases: Setup, Core Implementation, Integration, Testing, Polish
- Each task has status, wired, and verified fields
- Tasks link back to specific requirements
- Dependencies are declared explicitly
- Tasks sync to Claude Code's todo system

Output: `tasks.md`

See [Tasks](tasks.md).

## Stage 4: Execution

Three modes are available depending on how much oversight you want:

| Mode | Command/Script | When to use |
|------|---------------|-------------|
| Single iteration | `/spec-exec` | Manual step-by-step control |
| Automated loop | `spec-loop.sh` | Run all tasks unattended |
| Agent team | `spec-team.sh` | When you need review before each commit |

All execution modes use git worktrees for branch isolation and checkpoint commits for crash recovery.

See [Execution](execution.md).

## Stage 5: Post-implementation

After all tasks are verified, run the post-implementation pipeline in order:

```bash
spec-accept.sh   # user acceptance testing
spec-docs.sh     # generate documentation
spec-release.sh  # release notes and changelog
spec-verify.sh   # post-deployment smoke test
spec-retro.sh    # retrospective
```

See [Post-implementation](post-implementation.md).

## Refinement

Requirements and design can be updated at any time with `/spec-refine`. Changes cascade: updated requirements prompt a design review, and updated design prompts task regeneration with `/spec-tasks`.

## Status and validation

- `/spec-status` — current progress, task counts, dependency status
- `/spec-validate` — checks EARS notation, design coverage, task traceability, and cross-document consistency
