---
name: spec
description: Start a new spec-driven development workflow for a feature
argument-hint: "<feature-name>"
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - TaskCreate
  - TaskUpdate
  - TaskList
  - AskUserQuestion
---

# /spec Command

Create a new specification for a feature using the 3-phase spec-driven workflow.

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

Use templates from `${CLAUDE_PLUGIN_ROOT}/templates/` as starting points.

### 2. Requirements Phase (Interactive)

Guide the user through requirements gathering:

1. Ask about the feature's purpose and goals
2. Identify user roles and personas
3. Gather user stories with acceptance criteria
4. Use EARS notation for all acceptance criteria:
   ```
   WHEN [condition]
   THE SYSTEM SHALL [behavior]
   ```
5. Identify non-functional requirements (performance, security, accessibility)
6. Document out-of-scope items
7. List open questions

Write results to `.claude/specs/<feature-name>/requirements.md`

### 3. Design Phase (Interactive)

Guide the user through technical design:

1. Review requirements with the user
2. Discuss architectural approach
3. Identify major components
4. Define data models and schemas
5. Design APIs if applicable
6. Document sequence diagrams for key flows
7. Discuss alternatives and trade-offs
8. Address security and performance considerations

Write results to `.claude/specs/<feature-name>/design.md`

### 4. Tasks Phase

Break down design into implementation tasks:

1. Analyze design for discrete implementation units
2. Create tasks organized by phase:
   - Phase 1: Setup/Foundation
   - Phase 2: Core Implementation
   - Phase 3: Integration
   - Phase 4: Testing
   - Phase 5: Polish
3. Each task must have:
   - Clear title (imperative form)
   - Link to requirements (US-X)
   - Detailed description
   - Testable acceptance criteria
   - Dependencies
4. Write tasks to `.claude/specs/<feature-name>/tasks.md`

### 5. Sync Tasks to Claude Code

After creating tasks.md, sync to Claude Code's todo system:

```
For each task in tasks.md:
  TaskCreate(
    subject: task title,
    description: full task description with acceptance criteria,
    activeForm: present continuous form of action
  )
```

Set up dependencies between tasks using TaskUpdate with addBlockedBy.

### 6. Summary

After completing all phases, provide a summary:

- Number of user stories created
- Number of tasks created
- Key architectural decisions made
- Next steps for implementation

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
