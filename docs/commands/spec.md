# /spec

Start a new spec-driven development workflow for a feature. This command guides you through requirements gathering interactively, then produces a complete specification with requirements, architecture design, and implementation tasks.

## Usage

```
/spec <feature-name>
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `feature-name` | Yes | Name for the feature spec. Kebab-case recommended (e.g., `user-authentication`). |

## What It Does

1. **Creates the spec directory** at `.claude/specs/<feature-name>/` with three files: `requirements.md`, `design.md`, and `tasks.md`.

2. **Detects workflow mode** — if your input signals that you already have a design (mentions of architecture, RFC, diagram, whiteboard), the agent asks whether to start with design and derive requirements from it.

3. **Gathers input interactively** — in Requirements-First mode, asks about feature scope, user roles, and behaviors. In Design-First mode, asks about architecture, components, data models, and API contracts. Runs in 2-3 conversational rounds.

4. **Writes requirements and design** — produces `requirements.md` with EARS-notation acceptance criteria and `design.md` covering architecture, components, and data models. The order depends on the workflow mode.

5. **Generates implementation tasks** — breaks the design into phased tasks (Setup, Core Implementation, Integration, Testing, Polish) and syncs them to the Claude Code task list.

6. **Summarizes the result** — reports the number of user stories and tasks created, key architectural decisions, and suggests next steps.

## Example

```
/spec user-authentication
```

Claude will ask about your authentication requirements (OAuth? Email/password? Role-based access?), gather your answers, then produce a full spec ready for implementation.

## Tips

- Use `/spec-brainstorm` first if the idea is still vague. It helps clarify scope before committing to a spec.
- Keep requirements focused on *what* the system should do, not *how* it should do it.
- Run `/spec-validate` after the spec is created to catch any gaps before you start coding.
- For implementation, use `/spec-exec` (one task at a time) or `/spec-loop` (run until complete).

!!!tip
    If you have an existing PRD or design doc, paste its contents as context when running `/spec <name>`. If the agent detects design signals, it will offer Design-First mode so requirements are derived from your architecture rather than the other way around.

## See Also

- [/spec-brainstorm](spec-brainstorm.md) — Explore the idea conversationally before creating a spec
- [/spec-validate](spec-validate.md) — Validate the spec before implementation
- [/spec-exec](spec-exec.md) — Implement one task at a time
- [/spec-loop](spec-loop.md) — Run implementation until all tasks complete
