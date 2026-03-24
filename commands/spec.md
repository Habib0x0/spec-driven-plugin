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
| Requirements Gathering | /spec command (inline) | Current model | Interactive — needs AskUserQuestion |
| Requirements + Design Writing | spec-planner agent | Opus 4.5 | Deep reasoning for edge cases and architecture |
| Tasks | spec-tasker agent | Sonnet | Fast, structured task generation |
| Validation | spec-validator agent | Sonnet | Checklist-based verification |

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

Delegate to the **spec-planner** agent using the Task tool. This agent runs on **Opus 4.5** for deep reasoning.

Pass the agent ALL of the following context:
- The feature name
- The spec directory path
- **The complete user answers from step 2** (formatted clearly)
- **Relevant codebase context** (existing patterns, tech stack, conventions you discovered)
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
- To read the completed requirements.md and design.md
- To generate tasks and sync to Claude Code todos

### 5. Summary

After all agents complete, provide a summary:

- Number of user stories created
- Number of tasks created
- Key architectural decisions made
- Model usage: user interaction inline, Opus for spec writing, Sonnet for tasks
- Next steps: suggest running `/spec-validate` before implementation
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
