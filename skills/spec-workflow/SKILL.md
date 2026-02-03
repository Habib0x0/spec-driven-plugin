---
name: spec-workflow
description: This skill should be used when the user asks to "create a spec", "write requirements", "design a feature", "plan implementation", "use EARS notation", "create user stories", "break down tasks", "write a PRD", "technical specification", or mentions "spec-driven development", "feature spec", "requirements phase", "design phase", or "tasks phase". Provides structured 3-phase workflow for feature development.
version: 1.0.0
---

# Spec-Driven Development Workflow

A structured approach to feature development through three phases: Requirements, Design, and Tasks. This methodology prevents ad-hoc coding by ensuring proper planning before implementation.

## Overview

Spec-driven development transforms vague feature ideas into formal, traceable specifications:

```
Feature Idea → Requirements (EARS) → Design (Architecture) → Tasks (Trackable)
```

All spec files are stored in `.claude/specs/<feature-name>/`:
- `requirements.md` - User stories with EARS acceptance criteria
- `design.md` - Architecture, components, data flow
- `tasks.md` - Implementation tasks synced to Claude Code todos

## Phase 1: Requirements

Capture WHAT the system should do using EARS (Easy Approach to Requirements Syntax).

### EARS Notation

Structure requirements as testable statements:

```
WHEN [condition/trigger]
THE SYSTEM SHALL [expected behavior]
```

**Examples:**
```
WHEN a user submits a login form with valid credentials
THE SYSTEM SHALL authenticate the user and redirect to dashboard

WHEN a user submits invalid form data
THE SYSTEM SHALL display inline validation errors without page reload

WHEN an API request fails after 3 retries
THE SYSTEM SHALL display a user-friendly error message and log the failure
```

### User Story Format

```markdown
### US-1: [Story Title]

**As a** [user role]
**I want** [goal/desire]
**So that** [benefit/value]

#### Acceptance Criteria (EARS)

1. WHEN [condition]
   THE SYSTEM SHALL [behavior]
```

### Requirements Phase Workflow

1. Ask clarifying questions about the feature scope
2. Identify user roles and their goals
3. Write user stories with EARS acceptance criteria
4. Identify non-functional requirements (performance, security, accessibility)
5. Document out-of-scope items explicitly
6. List open questions for resolution

For detailed EARS patterns and examples, consult `references/ears-notation.md`.

## Phase 2: Design

Define HOW the system will implement the requirements.

### Design Components

1. **Architecture Overview** - High-level component diagram
2. **Data Flow** - How data moves through the system
3. **Component Specifications** - Purpose, responsibilities, interfaces
4. **Data Models** - Schemas, types, relationships
5. **API Design** - Endpoints, request/response formats
6. **Sequence Diagrams** - Key interaction flows

### Design Phase Workflow

1. Review all requirements from Phase 1
2. Identify major components needed
3. Define interfaces between components
4. Design data models and storage
5. Plan API contracts if applicable
6. Document security and performance considerations
7. List alternatives considered with rationale

For detailed design patterns, consult `references/design-patterns.md`.

## Phase 3: Tasks

Break down the design into discrete, trackable implementation tasks.

### Task Structure

```markdown
### T-1: [Task Title]

- **Status**: pending | in_progress | completed
- **Requirements**: US-1, US-2
- **Description**: [Detailed description]
- **Acceptance**: [How to verify completion]
- **Dependencies**: T-0 | none
```

### Task Breakdown Principles

1. **Single Responsibility** - Each task does one thing
2. **Testable** - Clear acceptance criteria
3. **Traceable** - Links to requirements
4. **Sequenced** - Dependencies explicit
5. **Time-boxed** - Completable in reasonable scope

### Task Phases

Organize tasks into logical phases:

1. **Setup** - Project scaffolding, dependencies, configuration
2. **Core Implementation** - Main feature functionality
3. **Integration** - Connect components, APIs
4. **Testing** - Unit, integration, E2E tests
5. **Polish** - Error handling, edge cases, cleanup

### Tasks Phase Workflow

1. Review design from Phase 2
2. Identify discrete implementation units
3. Sequence tasks based on dependencies
4. Link each task to requirements
5. Define acceptance criteria per task
6. Sync tasks to Claude Code todos using TaskCreate

For detailed task breakdown strategies, consult `references/task-breakdown.md`.

## Spec File Location

Create specs in the project's `.claude/specs/` directory:

```
project/
├── .claude/
│   └── specs/
│       └── user-authentication/
│           ├── requirements.md
│           ├── design.md
│           └── tasks.md
└── src/
```

## Integration with Claude Code

### Creating Specs

Use the `/spec <feature-name>` command to start a new spec with interactive guidance through all three phases.

### Task Synchronization

After completing the Tasks phase, sync to Claude Code todos:

```
For each task in tasks.md:
  TaskCreate with subject, description, and dependencies
```

### Auto-Context

When implementing features, Claude automatically includes relevant spec files as context. This ensures implementation stays aligned with requirements.

### Refinement

Use `/spec-refine` to update requirements or design. Changes cascade:
- Updated requirements → Review design
- Updated design → Regenerate tasks

## Templates

Templates are available at `${CLAUDE_PLUGIN_ROOT}/templates/`:
- `requirements.md` - Requirements template with EARS format
- `design.md` - Design document template
- `tasks.md` - Task tracking template

## Quick Reference

| Phase | Focus | Output | Key Question |
|-------|-------|--------|--------------|
| Requirements | WHAT | User stories + EARS | What should it do? |
| Design | HOW | Architecture docs | How will it work? |
| Tasks | WHEN | Task list + todos | What's the sequence? |

## Additional Resources

### Reference Files

For detailed guidance on each phase:
- **`references/ears-notation.md`** - Complete EARS patterns and examples
- **`references/design-patterns.md`** - Architecture documentation patterns
- **`references/task-breakdown.md`** - Task decomposition strategies

### Commands

- `/spec <name>` - Start new spec
- `/spec-refine` - Update existing spec
- `/spec-tasks` - Regenerate tasks
- `/spec-status` - View progress
- `/spec-validate` - Validate completeness
