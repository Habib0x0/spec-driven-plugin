# /spec-brainstorm

Explore and refine a feature idea through open-ended conversation before committing to a formal spec. Use this when the idea is still vague, when you're weighing competing approaches, or when you want to check feasibility before writing requirements.

## Usage

```
/spec-brainstorm [idea]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `idea` | No | An initial description of what you're thinking about. If omitted, Claude will ask. |

## What It Does

1. **Understands your starting point** — reads relevant parts of the codebase to understand existing patterns, constraints, and architecture before the conversation begins.

2. **Offers domain expert consultation** — optionally brings in specialized perspectives during the session. Available experts: Software Architect, Security Expert, ERP/Enterprise Expert, UX Designer, DevOps/Infrastructure, Performance Engineer. You can select multiple.

3. **Explores the idea iteratively** — asks focused questions across multiple rounds: What problem are we solving? Who experiences it? What's the simplest useful version? What are we explicitly not doing? What are the risks?

4. **Consults experts at decision points** — when the discussion hits a domain-specific trade-off, the relevant expert weighs in. Their analysis is integrated conversationally, not dumped as raw output.

5. **Produces a feature brief** — when the idea feels solid, synthesizes the conversation into a structured brief covering problem statement, proposed solution, key behaviors, user roles, expert recommendations, out-of-scope items, and open questions.

6. **Hands off to /spec** — ends with a ready-to-use brief and a suggested `/spec <feature-name>` command to formalize it.

## Example

```
/spec-brainstorm "I want better error handling across the API"
```

Claude will ask clarifying questions, explore whether you mean user-facing errors, internal logging, retry logic, or all three, and help you land on a clear scope before you commit to writing requirements.

## Tips

- It is fine for the conversation to take 5 or more rounds. There is no rush to converge.
- If you feel stuck, ask Claude to suggest concrete options to react to rather than answering open-ended questions.
- Experts supplement your thinking — if you already have strong opinions in a domain, skip that expert.
- The brief produced at the end becomes your starting context when you run `/spec`.

!!!tip
    Use this command any time the scope of a feature is unclear. Spending 10 minutes here prevents hours of rework from a poorly scoped spec.

## See Also

- [/spec](spec.md) — Formalize the idea into requirements, design, and tasks
- [/spec-import](spec-import.md) — Convert an existing document into a spec instead
