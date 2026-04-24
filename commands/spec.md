---
name: spec
description: Start a new spec-driven development workflow for a feature
argument-hint: "<feature-name>"
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Task
  - TaskCreate
  - TaskUpdate
  - TaskList
  - AskUserQuestion
---

# /spec Command

Create a new specification for a feature using the 3-phase spec-driven workflow. Requirements are gathered interactively with the user, then agents handle the heavy writing.

## Model Routing

| Phase | Who | Model Tier | Why |
|-------|-----|------------|-----|
| Phase 0 Scan | spec-scanner agent | sonnet | Fast multi-file reading; reasoning depth not critical |
| Requirements Gathering | /spec command (inline) | Current model | Interactive — needs AskUserQuestion |
| Requirements + Design Writing | spec-planner agent | opus | Deep reasoning for edge cases and architecture |
| Tasks | spec-tasker agent | sonnet | Fast, structured task generation |
| Validation | spec-validator agent | sonnet | Checklist-based verification |

## Model Override

Each agent spawn below reads a `SPEC_MODEL_*` environment variable. When the variable is set and non-empty, pass its value as the `model:` parameter to the Task tool, overriding the agent's frontmatter tier alias. When unset, omit `model:` from the Task invocation and the agent runs on its frontmatter default.

| Env var | Agent | Default tier |
|---------|-------|--------------|
| `SPEC_MODEL_SCANNER` | spec-scanner | sonnet |
| `SPEC_MODEL_PLANNER` | spec-planner | opus |
| `SPEC_MODEL_TASKER` | spec-tasker | sonnet |
| `SPEC_MODEL_VALIDATOR` | spec-validator | sonnet |

Example spawn with override: `Task(subagent_type="spec-planner", model="$SPEC_MODEL_PLANNER", prompt=...)` when `SPEC_MODEL_PLANNER` is set. See `docs/advanced/model-routing.md` for full details.

## Arguments

- `feature-name` (required): Name for the feature spec (kebab-case recommended)

## Workflow

### 1. Initialize Spec Directory

Create the spec directory structure:

```
.claude/specs/<feature-name>/
├── requirements.md
├── design.md
└── tasks.md
```

Use templates from `${CLAUDE_PLUGIN_ROOT}/templates/` as starting points. Copy each template to the spec directory.

### 1.5. Phase 0: Project Profile Check

Before gathering requirements, check for (or create) a project profile so that downstream agents have codebase context.

1. **Check for existing profile**: Use Glob to look for `.claude/specs/_project-profile.md` or `.claude/specs/_profile-index.md` in the project root.

2. **If neither exists — invoke spec-scanner**:
   - Use the Task tool to invoke the `spec-scanner` agent (subagent_type: `spec-scanner`).
   - Pass the project root as the working directory.
   - The scanner will analyze the codebase and write `.claude/specs/_project-profile.md` (or split files + `_profile-index.md` for large projects).
   - Wait for the scanner to complete before proceeding.

3. **If a profile already exists — read it**:
   - Read the full content of `_project-profile.md` (or for split profiles, read `_profile-index.md` and then each referenced domain file).

4. **Store profile content**: Keep the profile content available as `PROJECT_PROFILE` context to pass to the spec-planner and spec-tasker agents in subsequent steps.

### 2. Interactive Requirements Gathering (inline — NOT delegated)

**IMPORTANT**: This phase runs inline in the /spec command, NOT in a subagent. This is because subagents cannot interact with the user via AskUserQuestion.

#### 2a. Pre-Analysis (before asking any questions)

Before presenting questions, perform thorough codebase analysis to build **evidence-based** recommendations. Recommendations must be grounded in actual code, not generic assumptions.

1. **Parse the feature name** — Identify keywords and map them to likely domain concepts (e.g., `user-authentication` maps to auth, sessions, credentials)
2. **Read the project profile** — Use the `PROJECT_PROFILE` from Phase 0. Extract:
   - Tech stack (framework, language, database) — recommendations must align with what's actually in use
   - Existing entities from the Entity Registry — identify which are relevant to this feature
   - Patterns (with confidence levels) — recommendations should follow detected patterns, especially high-confidence ones
   - Registration points — know where new code needs to be wired in
3. **Deep codebase scan** — This is critical for accurate recommendations:
   - Use Glob to find files matching the feature's domain (e.g., for `payment-processing`: `**/payment*`, `**/billing*`, `**/checkout*`, `**/order*`)
   - Use Grep to find related constants, types, interfaces, routes, and handlers
   - Read the most relevant files (models, services, controllers, routes) to understand existing data shapes, API patterns, and business logic
   - Check for existing tests to understand testing patterns
   - Look at similar completed features for structural precedent
4. **Synthesize evidence-based recommendations** — For each question category below, draft a recommendation citing what you found. Every recommendation must reference specific files, patterns, or entities from the codebase. If you don't have enough evidence for a category, say so explicitly rather than guessing.

#### 2b. Questions with Recommended Defaults

Use AskUserQuestion to gather requirements, but present each question with an **evidence-based recommended default** the user can accept, modify, or override. Structure each round as:

```
Based on my analysis of the codebase, here are my recommendations:

**Feature scope**: [recommendation]
  - Evidence: [cite specific files, patterns, or entities that informed this]

**User roles**: [recommendation]
  - Evidence: [cite existing role definitions, auth middleware, or user models found]

**Key behaviors**: [recommendation]
  - Evidence: [cite similar flows, existing routes/handlers, or API patterns found]

Do these look right? You can:
- Accept as-is ("looks good")
- Adjust specific parts ("yes but change X to Y")
- Override entirely with your own answer
```

**Quality bar for recommendations**: Only recommend what the codebase evidence supports. If a category has weak or no evidence (e.g., no existing auth patterns for a security question), present it as an open question rather than a low-confidence guess. A recommendation that says "I didn't find existing patterns for this — what are your requirements?" is better than a generic guess.

The user can respond with:
- **"looks good"** / **"yes"** / **"use defaults"** — Accept the recommendations as-is and move on
- **Partial edits** — "Yes but also add X" or "Change the scope to Y" — Merge their edits with the defaults
- **Full override** — Provide their own detailed answer, ignoring the recommendation

Ask about these categories across 2-3 rounds:

**Round 1 (scope and roles):**
1. **Feature scope** — What is the core problem this feature solves? What are the boundaries?
2. **User roles** — Who will use this feature? What are their goals?
3. **Key behaviors** — What are the main actions/flows? What should happen in each?

**Round 2 (constraints and boundaries):**
4. **Edge cases and errors** — What happens when things go wrong? Invalid input? Network failures?
5. **Security concerns** — Authentication, authorization, data sensitivity?
6. **Non-functional requirements** — Performance expectations? Accessibility? Scalability?

**Round 3 (if needed — skip if rounds 1-2 were comprehensive):**
7. **Out of scope** — What explicitly should NOT be included?
8. **Open questions** — Anything ambiguous that needs clarification?

For rounds 2-3, refine your recommendations based on the user's answers from earlier rounds. If the user accepted defaults in round 1, use that signal to provide stronger defaults in round 2 (they likely want a faster flow).

#### 2c. Codebase Context

Throughout the gathering, also read relevant existing code to understand current architecture, patterns, and conventions. Include this as part of the structured brief even if the user didn't mention it — this context is always valuable.

Collect all answers (user-provided and accepted defaults) into a structured brief.

### 3. Requirements + Design Writing (via spec-planner agent)

Delegate to the **spec-planner** agent using the Task tool. This agent runs on the **opus tier** for deep reasoning. If `SPEC_MODEL_PLANNER` is set, pass it as the `model:` parameter to override.

Pass the agent ALL of the following context:
- The feature name
- The spec directory path
- **The complete user answers from step 2** (formatted clearly)
- **Relevant codebase context** (existing patterns, tech stack, conventions you discovered)
- **The PROJECT_PROFILE content from Phase 0** (if available — this gives the planner Entity Registry, Registration Points, Regression Markers, and stack details for profile-aware requirements and design)
- Instruction to write both requirements.md (with EARS notation) and design.md
- Instruction to NOT ask clarifying questions — all user input has already been gathered

The spec-planner agent will:
1. Write comprehensive requirements with EARS acceptance criteria based on user answers
2. Design the architecture based on requirements and codebase context
3. Write both requirements.md and design.md to the spec directory

### 4. Tasks Phase (via spec-tasker agent)

After the spec-planner completes, delegate to the **spec-tasker** agent using the Task tool. This agent runs on the **sonnet tier** for efficient task breakdown. If `SPEC_MODEL_TASKER` is set, pass it as the `model:` parameter to override.

Tell the spec-tasker agent:
- The feature name
- The spec directory path
- **The PROJECT_PROFILE content from Phase 0** (if available — this gives the tasker Registration Points and Patterns context for generating wiring-aware tasks)
- To read the completed requirements.md and design.md
- To generate tasks and sync to Claude Code todos

### 4.5. Auto-Validate and Fix

After the spec-tasker completes (and before the summary), run an automated validate-fix loop to catch and resolve spec issues without requiring a manual `/spec-validate` run.

**Loop (up to 3 cycles):**

1. **Invoke spec-validator**: Use the Task tool to invoke the `spec-validator` agent (subagent_type: `spec-validator`), passing the spec directory path. The validator checks requirements (EARS notation, no vague terms), design (covers all requirements), and tasks (traceability, valid dependencies, no cycles).

2. **Parse validator output**: Read the validator's response for errors and warnings. If the validator reports zero issues, exit the loop immediately — no further cycles needed.

3. **Route fixes to the appropriate agent**:
   - **Requirements or design issues** (e.g., vague acceptance criteria, missing EARS notation, design gaps): invoke the `spec-planner` agent via Task tool, passing:
     - The spec directory path
     - The full validator report
     - The PROJECT_PROFILE content (if available)
     - Explicit instruction: **"Fix ONLY the specific issues listed below. Do not rewrite sections that passed validation."**
   - **Task issues** (e.g., missing requirement IDs, invalid dependencies, traceability gaps): invoke the `spec-tasker` agent via Task tool, passing:
     - The spec directory path
     - The full validator report
     - Explicit instruction: **"Fix ONLY the specific issues listed below. Do not rewrite sections that passed validation."**
   - If both requirement/design and task issues exist, fix requirement/design issues first (since task fixes may depend on corrected requirements), then fix task issues.

4. **Re-invoke validator**: After the fix agent completes, go back to step 1 and re-validate.

5. **Exit conditions**:
   - **All issues resolved**: Set `VALIDATION_STATUS` to `"Spec validated: PASS"` and exit loop.
   - **3 cycles exhausted with remaining issues**: Set `VALIDATION_STATUS` to `"X errors and Y warnings remaining after 3 validation cycles"` (with actual counts) and exit loop.

### 5. Summary

After all agents complete, provide a summary:

- Number of user stories created
- Number of tasks created
- Key architectural decisions made
- **Validation status**: Display the `VALIDATION_STATUS` from step 4.5 (either `"Spec validated: PASS"` or the remaining issue count)
- Model usage: user interaction inline, opus tier for spec writing, sonnet tier for tasks
- If validation passed: suggest running `/spec-exec` or `/spec-loop` for implementation
- If warnings remain: suggest running `/spec-validate` manually to review remaining issues before implementation
- Remind user: for implementation, use `/spec-exec` (single task) or `/spec-loop` (all tasks)

## Example Usage

```
/spec user-authentication
/spec shopping-cart
/spec real-time-notifications
```

## Tips

- Keep requirements focused on WHAT, not HOW
- Design should address all requirements
- Tasks should trace back to requirements
- Start with the happy path, then add error handling tasks
- Include testing tasks for each major component
- After spec is complete, use `/spec-exec` or `/spec-loop` for autonomous implementation
