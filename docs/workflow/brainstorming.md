# Brainstorming

The brainstorm phase is an optional free-form conversation before you formalize a spec. It is useful when you have a vague idea that needs exploration before committing to requirements.

## When to brainstorm

Use `/spec-brainstorm` when:

- The idea is not yet fully defined
- You are weighing multiple approaches
- The scope is unclear
- You want to think through feasibility before committing
- You want expert input on trade-offs

If you already know exactly what you want to build, skip brainstorming and go straight to `/spec`.

## How it works

```
/spec-brainstorm [idea]
```

The session is conversational. The agent reflects back what it understands, asks 1-2 focused questions per round, and offers observations about things you may not have considered.

Topics explored over multiple rounds:

- What problem are we actually solving?
- Who experiences this problem?
- What does success look like?
- What is the simplest version that would be useful?
- What are we explicitly not doing?
- What are the risks or unknowns?
- Are there existing patterns in the codebase to follow?

## Expert consultants

At the start of the session, the agent asks whether you want domain expert consultants available. If yes, you can select from:

| Expert | Domain |
|--------|--------|
| Software Architect | System design, scalability, component boundaries |
| Security Expert | Threat modeling, authentication, data protection |
| ERP/Enterprise Expert | Business workflows, multi-tenancy, auditing |
| UX Designer | User flows, accessibility, interaction patterns |
| DevOps/Infrastructure | Deployment, CI/CD, monitoring |
| Performance Engineer | Bottlenecks, caching, load patterns |

You can also describe a custom expert role.

When the conversation hits a domain-specific trade-off or knowledge gap, the agent spawns a `spec-consultant` sub-agent to analyze the specific question. Expert input is integrated conversationally — the agent synthesizes it rather than dumping raw analysis.

Experts are only consulted on topics relevant to their domain. The same expert is not re-spawned without meaningful new context.

## The brief

When the conversation converges, the agent outputs a structured brief:

```markdown
## Feature Brief: [Feature Name]

### Problem Statement
...

### Proposed Solution
...

### Key Behaviors
- ...

### User Roles
- ...

### Expert Analysis (if consultants were used)
...

### Out of Scope
- ...

### Open Questions
- ...

### Codebase Context
- ...
```

Use this brief as input when running `/spec <feature-name>` to start the formal specification.

## Tips

- The session can take five or more rounds — do not rush to conclusions
- Reference specific code files when discussing feasibility
- Expert consultants supplement the conversation; they do not replace it
- If experts give conflicting advice, the agent presents both perspectives and lets you decide
