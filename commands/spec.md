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

### 2. Preset Selection (inline)

Before gathering requirements, ask the user whether they want to start from a preset template or from scratch.

Use AskUserQuestion with the following prompt:

> Would you like to start from a preset template or from scratch?

Provide these options:
- **REST API** — Pre-filled user stories for CRUD, validation, auth, errors, pagination
- **React Page** — Pre-filled user stories for rendering, routing, state, API integration, responsive layout
- **CLI Tool** — Pre-filled user stories for arg parsing, subcommands, output formatting, errors, help/version
- **Start from scratch** — Blank requirements (v2.x behavior)

Based on the user's selection:
- If a preset is selected: read the corresponding file from `${CLAUDE_PLUGIN_ROOT}/templates/presets/<slug>.md` (slugs: `rest-api`, `react-page`, `cli-tool`). Store the content to pass to the spec-planner agent in step 4.
- If "Start from scratch" is selected: do not read any preset file. Continue with the existing flow unchanged — no preset context will be passed to the planner.

### 3. Interactive Requirements Gathering (inline — NOT delegated)

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

### 4. Requirements + Design Writing (via spec-planner agent)

Delegate to the **spec-planner** agent using the Task tool. This agent runs on **Opus 4.5** for deep reasoning.

Pass the agent ALL of the following context:
- The feature name
- The spec directory path
- **The complete user answers from step 3** (formatted clearly)
- **Relevant codebase context** (existing patterns, tech stack, conventions you discovered)
- Instruction to write both requirements.md (with EARS notation) and design.md
- Instruction to NOT ask clarifying questions — all user input has already been gathered
- **If a preset was selected in step 2**: include the preset content, labeled as "Preset Template (customize for this specific feature — do not use verbatim)". Instruct the planner to use the preset as a starting point and adapt it to the user's specific answers — not copy it wholesale.
- **If no preset was selected**: do not include any preset context.

The spec-planner agent will:
1. Write comprehensive requirements with EARS acceptance criteria based on user answers (and preset if provided)
2. Design the architecture based on requirements and codebase context
3. Write both requirements.md and design.md to the spec directory

### 5. Tasks Phase (via spec-tasker agent)

After the spec-planner completes, delegate to the **spec-tasker** agent using the Task tool. This agent runs on **Sonnet** for efficient task breakdown.

Tell the spec-tasker agent:
- The feature name
- The spec directory path
- To read the completed requirements.md and design.md
- To generate tasks and sync to Claude Code todos

### 6. Summary

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
