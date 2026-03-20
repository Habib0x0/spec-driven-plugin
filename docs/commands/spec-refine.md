# /spec-refine

Update requirements or architecture design for an existing spec. Use this when requirements change, new edge cases are discovered, or the design needs revision after implementation has started.

## Usage

```
/spec-refine
```

No arguments — the command detects available specs and prompts you to select one if multiple exist.

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| _(none)_ | — | The command is interactive. Select the spec and describe changes when prompted. |

## What It Does

1. **Identifies the spec to refine** — lists specs in `.claude/specs/`. If only one exists, it is selected automatically. If multiple exist, you are asked to choose.

2. **Reads the current spec** — loads both `requirements.md` and `design.md` so Claude has full context before asking what needs to change.

3. **Gathers refinements** — asks what needs updating: new requirements to add, existing ones to modify or remove, design changes, new components or APIs.

4. **Updates requirements** — adds new user stories with EARS acceptance criteria, modifies existing stories, and marks removed requirements as deprecated rather than deleting them. Change history is preserved.

5. **Updates design** — if requirements changed, reviews impacted components, updates architecture descriptions, data models, API specifications, and sequence diagrams.

6. **Flags task impact** — after updating the spec, identifies which existing tasks may be affected and suggests running `/spec-tasks` to regenerate the task list.

## Example

```
/spec-refine
```

Then follow the prompts: select your spec, describe what changed (e.g., "we need to support OAuth in addition to email/password"), and Claude updates the documents.

## Tips

- Preserve change history — add notes about what changed and why. This context is valuable during implementation and retrospectives.
- After any significant requirement change, always review the design for consistency.
- After design changes, always regenerate tasks with `/spec-tasks` to keep implementation in sync.
- Deprecated requirements should stay in the document (marked deprecated) rather than be deleted — they explain why certain design decisions were made.

!!!note
    Refinements cascade: requirements changes may require design updates, which in turn require task updates. Work top-down and run `/spec-tasks` at the end.

## See Also

- [/spec-tasks](spec-tasks.md) — Regenerate tasks after refining requirements or design
- [/spec-validate](spec-validate.md) — Validate the updated spec before continuing implementation
- [/spec-status](spec-status.md) — Check which tasks may be affected by the changes
