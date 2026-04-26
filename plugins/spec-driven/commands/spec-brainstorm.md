---
description: Brainstorm a feature idea through conversation until it's ready for /spec
---

# /spec-brainstorm

Have a back-and-forth conversation to explore and refine a feature idea. No structured output yet — just discussion until the idea is solid. When ready, output a brief for `/spec`.

Optionally bring in domain expert consultants for specialized analysis at key decision points.

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

### 2. Offer Expert Consultation (Optional)

Ask the user if they'd like domain expert consultants available during the session.

Use AskUserQuestion:
- **"No experts needed"** — Skip to Step 3 (standard brainstorm)
- **"Yes, bring in experts"** — Select consultants below

If they want experts, use AskUserQuestion with `multiSelect: true`:

- **Software Architect** — System design, scalability, component boundaries, integration patterns
- **Security Expert** — Threat modeling, authentication, data protection, compliance
- **ERP/Enterprise Expert** — Business workflows, data modeling, multi-tenancy, auditing
- **UX Designer** — User flows, accessibility, interaction patterns, information architecture
- **DevOps/Infrastructure** — Deployment, CI/CD, monitoring, containerization
- **Performance Engineer** — Bottlenecks, caching strategies, load patterns, optimization

If the user selects "Other," follow up asking them to describe the custom expert role and domain expertise.

Store the selected expert list for the session.

### 3. Iterative Exploration

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

#### Expert Consultation (if experts were selected)

Spawn a `spec-driven:spec-consultant` agent via the Task tool when:
- The discussion hits a **domain-specific trade-off** (e.g., security vs. UX, performance vs. simplicity)
- You identify a **gap** in your or the user's knowledge that an expert could fill
- The user **asks** about a topic that maps to a selected expert
- Every **2-3 conversational rounds**, check if any selected expert would have useful input on what's been discussed

**How to spawn a consultant:**

Use the Task tool to spawn a `spec-driven:spec-consultant` agent. The agent runs on the **sonnet tier** by default. If the `SPEC_MODEL_CONSULTANT` environment variable is set and non-empty, pass its value as the `model:` parameter to the Task tool (e.g., `Task(subagent_type="spec-consultant", model="$SPEC_MODEL_CONSULTANT", prompt=...)`). Otherwise omit `model:` and the agent uses its frontmatter default.

In the prompt, provide:

1. **Expert Role**: The specific role (e.g., "Security Expert")
2. **Domain Expertise**: What this expert specializes in
3. **Discussion Context**: A concise summary of the conversation so far
4. **Specific Question**: The precise question you want the expert to analyze
5. **Codebase Context**: Relevant file paths and patterns you've discovered

Example spawn prompt:
```
You are a Security Expert specializing in threat modeling, authentication, data protection, and compliance.

## Discussion Context
We're brainstorming a user authentication feature for a Next.js app. The user wants social login (Google, GitHub) plus email/password. We're considering storing sessions in JWTs vs server-side sessions.

## Specific Question
What are the security implications of JWT-based sessions vs server-side sessions for this use case? Consider token theft, session invalidation, and OWASP best practices.

## Codebase Context
- Current auth: none (greenfield)
- Framework: Next.js 14 with App Router
- Database: PostgreSQL via Prisma
- Relevant files: src/app/api/ (API routes), prisma/schema.prisma
```

**After receiving expert analysis:**

- Synthesize it conversationally: *"I consulted with our Security Expert, and they raised some important points..."*
- Present the key concerns and recommendations in your own words
- Ask the user how they want to respond to the expert's input
- Don't just dump the raw analysis — integrate it into the conversation

**Consultation guardrails:**
- Only spawn experts from the user's selected list
- Don't re-spawn the same expert without meaningful new context since their last consultation
- Can spawn multiple experts in parallel if the discussion spans domains
- Keep expert questions focused — one clear question per spawn, not a brain dump

### 4. Check for Readiness

After a few rounds, or when the conversation feels like it's converging, ask:

"I think we have a solid picture now. Ready to formalize this into a spec, or do you want to explore further?"

Use AskUserQuestion:
- **"Ready for /spec"** — Move to step 5
- **"Keep exploring"** — Continue the conversation
- **"Consult another expert"** — (if experts active) Request a specific expert consultation before moving on
- **"I want to change direction"** — Pivot to a new angle

### 5. Output the Brief

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

### Expert Analysis (if consultants were used)

#### [Expert Role 1] (e.g., Security Expert)
- **Key Concerns**: [Top concerns raised]
- **Recommendations**: [Actionable recommendations adopted or under consideration]
- **Design Constraints**: [Constraints this expert's input introduces]

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
- Experts supplement the discussion — they don't replace your role as thought partner
- Introduce expert input naturally: "Our architect suggests..." not "EXPERT ANALYSIS FOLLOWS"
- If experts disagree with each other, present both perspectives and let the user decide
- Don't over-consult — if the user has strong opinions in a domain, respect that and skip the expert
