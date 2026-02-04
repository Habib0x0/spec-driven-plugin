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

Create a new specification for a feature using the 3-phase spec-driven workflow. Each phase automatically uses the optimal model via specialized agents.

## Model Routing

| Phase | Agent | Model | Why |
|-------|-------|-------|-----|
| Requirements + Design | spec-planner | Opus 4.5 | Deep reasoning for edge cases and architecture |
| Tasks | spec-tasker | Sonnet | Fast, structured task generation |
| Validation | spec-validator | Sonnet | Checklist-based verification |

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

### 2. Requirements + Design Phase (via spec-planner agent)

Delegate to the **spec-planner** agent using the Task tool. This agent runs on **Opus 4.5** for deep reasoning about requirements and architecture.

Tell the spec-planner agent:
- The feature name
- The spec directory path
- To complete both Requirements (Phase 1) and Design (Phase 2)
- To write results to the spec directory

The spec-planner agent will:
1. Ask clarifying questions about the feature
2. Write requirements with EARS notation
3. Design the architecture
4. Write both requirements.md and design.md

### 3. Tasks Phase (via spec-tasker agent)

After the spec-planner completes, delegate to the **spec-tasker** agent using the Task tool. This agent runs on **Sonnet** for efficient task breakdown.

Tell the spec-tasker agent:
- The feature name
- The spec directory path
- To read the completed requirements.md and design.md
- To generate tasks and sync to Claude Code todos

### 4. Summary

After all agents complete, provide a summary:

- Number of user stories created
- Number of tasks created
- Key architectural decisions made
- Model usage: Opus for planning, Sonnet for tasks
- Next steps: suggest running `/spec-validate` before implementation
- Remind user: implementation works best with Sonnet (fast code generation from clear specs)

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
- After spec is complete, switch to Sonnet for implementation — the spec provides all the context needed
