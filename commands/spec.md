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

| Phase | Who | Model | Why |
|-------|-----|-------|-----|
| Phase 0 Scan | spec-scanner agent | Sonnet 4.6 | Fast multi-file reading; reasoning depth not critical |
| Requirements Gathering | /spec command (inline) | Current model | Interactive — needs AskUserQuestion |
| Requirements + Design Writing | spec-planner agent | Opus 4.6 | Deep reasoning for edge cases and architecture |
| Tasks | spec-tasker agent | Sonnet 4.6 | Fast, structured task generation |
| Validation | spec-validator agent | Sonnet 4.6 | Checklist-based verification |

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

Use AskUserQuestion to gather requirements from the user. Ask about:

1. **Feature scope** — What is the core problem this feature solves? What are the boundaries?
2. **User roles** — Who will use this feature? What are their goals?
3. **Key behaviors** — What are the main actions/flows? What should happen in each?
4. **Edge cases and errors** — What happens when things go wrong? Invalid input? Network failures?
5. **Security concerns** — Authentication, authorization, data sensitivity?
6. **Non-functional requirements** — Performance expectations? Accessibility? Scalability?
7. **Out of scope** — What explicitly should NOT be included?
8. **Existing codebase context** — Read relevant existing code to understand current architecture, patterns, and conventions.

Ask these as 2-3 rounds of questions using AskUserQuestion. Don't ask everything at once — let earlier answers inform later questions.

Collect all answers into a structured brief. Also include any relevant codebase context you discovered by reading existing files.

### 3. Requirements + Design Writing (via spec-planner agent)

Delegate to the **spec-planner** agent using the Task tool. This agent runs on **Opus 4.6** for deep reasoning.

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

After the spec-planner completes, delegate to the **spec-tasker** agent using the Task tool. This agent runs on **Sonnet** for efficient task breakdown.

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
- Model usage: user interaction inline, Opus for spec writing, Sonnet for tasks
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
