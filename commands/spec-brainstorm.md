---
name: spec-brainstorm
description: Brainstorm a feature idea through conversation until it's ready for /spec
argument-hint: "[idea]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - AskUserQuestion
---

# /spec-brainstorm Command

Have a back-and-forth conversation to explore and refine a feature idea. No structured output yet — just discussion until the idea is solid. When ready, output a brief for `/spec`.

## Philosophy

This is the "thinking out loud" phase. The user might have:
- A vague idea ("I want better error handling")
- A specific request they haven't fully thought through
- Multiple competing approaches they're weighing
- Questions about feasibility

Your job is to be a thought partner, not a spec writer. Ask probing questions, suggest alternatives, identify gaps, and help them arrive at clarity.

## Workflow

### 1. Understand the Starting Point

If the user provided an initial idea as an argument, acknowledge it and start exploring. If not, ask what they're thinking about.

Read relevant parts of the codebase to understand context:
- What does the current implementation look like?
- What patterns does this codebase use?
- What constraints exist?

### 2. Iterative Exploration

Have a natural conversation. In each round:

1. **Reflect back** what you understand so far
2. **Ask 1-2 focused questions** that dig deeper or challenge assumptions
3. **Offer observations** — things they might not have considered
4. **Suggest alternatives** when relevant

Use AskUserQuestion for structured choices when helpful, but don't overuse it. Sometimes a simple "What do you think about X?" in prose is better.

Topics to explore over multiple rounds:
- What problem are we actually solving?
- Who experiences this problem? How painful is it?
- What does success look like?
- What's the simplest version that would be useful?
- What are we explicitly NOT doing?
- Are there existing patterns in the codebase we should follow?
- What are the risks or unknowns?
- Have you considered [alternative approach]?

### 3. Check for Readiness

After a few rounds, or when the conversation feels like it's converging, ask:

"I think we have a solid picture now. Ready to formalize this into a spec, or do you want to explore further?"

Use AskUserQuestion:
- **"Ready for /spec"** — Move to step 4
- **"Keep exploring"** — Continue the conversation
- **"I want to change direction"** — Pivot to a new angle

### 4. Output the Brief

When the user is ready, synthesize the conversation into a structured brief:

```markdown
## Feature Brief: [Feature Name]

### Problem Statement
[1-2 sentences on what problem this solves]

### Proposed Solution
[High-level description of the approach]

### Key Behaviors
- [Behavior 1]
- [Behavior 2]
- [Behavior 3]

### User Roles
- [Role 1]: [What they need]
- [Role 2]: [What they need]

### Out of Scope
- [Thing we're explicitly not doing]
- [Another thing]

### Open Questions
- [Any unresolved items to address in /spec]

### Codebase Context
- [Relevant existing patterns]
- [Files/modules this will touch]
```

Then tell the user:

"Here's the brief. Run `/spec <feature-name>` to formalize this into requirements, design, and tasks. The brief above will be your starting context."

## Tips

- Keep it conversational, not interrogative
- It's OK if the conversation takes 5+ rounds
- Don't rush to conclusions — let the user think
- If they seem stuck, offer concrete options to react to
- Reference specific code when discussing feasibility
- It's fine to say "I'm not sure, let's figure it out together"

## Example Flow

```
User: /spec-brainstorm better error handling