# /research

Deep research before planning. Launches parallel agents to search docs, web, and codebase, then synthesizes findings into actionable context.

## Usage

```
/research <topic or question>
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `topic or question` | Yes | What to research — a concept, library, bug, or design question |

## What It Does

1. **Clarifies scope** — asks focused questions about the topic before starting any research, to avoid wasting time on the wrong angle.

2. **Launches parallel agents** — spawns up to 5 sub-agents simultaneously depending on the question:
   - **Codebase agent** — Grep/Glob/Read to find existing patterns and implementations
   - **Docs agent** — looks up official library or framework documentation via Context7 MCP or WebFetch
   - **Web agent** — searches for real-world solutions, Stack Overflow answers, GitHub issues
   - **Dependencies agent** — checks package versions, compatibility, and breaking changes
   - **UI/UX agent** — researches design patterns and interaction models (for frontend questions)

3. **Checks in after research** — surfaces key findings and unexpected results before synthesizing, giving you a chance to redirect.

4. **Synthesizes** — combines all agent findings, resolves contradictions, and evaluates whether the proposed approach is the best one.

5. **Stress-tests** — explicitly looks for downsides, edge cases, and maintenance costs of the recommended approach.

## Output Format

```
### Answer
Direct response to the question.

### Evidence
Code snippets, doc quotes, or data backing up the answer.

### Sources
File paths and URLs.

### Related
Gotchas, related patterns, upcoming deprecations.

### Downsides & Risks
What could go wrong with the recommended approach.
```

## When to Use

- Before writing a spec when you need to understand an unfamiliar domain
- When evaluating two competing approaches
- When debugging a problem you don't fully understand yet
- Before proposing an architectural change

## Example

```
/research how does session management work in our app
/research best approach for real-time notifications in Next.js
/research why is our auth middleware rejecting valid tokens
```

## See Also

- [/zoom-out](zoom-out.md) — Structural map of the codebase
- [/spec](spec.md) — Start a spec after research is complete
