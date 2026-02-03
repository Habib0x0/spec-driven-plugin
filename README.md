# Spec-Driven Development Plugin

A structured workflow plugin for Claude Code that transforms feature ideas into formal specifications before implementation.

## Overview

Inspired by Kiro's spec-driven approach, this plugin guides you through three phases:

1. **Requirements** - User stories with EARS notation and acceptance criteria
2. **Design** - Technical architecture, sequence diagrams, implementation considerations
3. **Tasks** - Discrete, trackable implementation items synced to Claude Code todos

## Commands

| Command | Description |
|---------|-------------|
| `/spec <feature-name>` | Start a new spec with interactive 3-phase workflow |
| `/spec-refine` | Refine requirements/design for current spec |
| `/spec-tasks` | Regenerate tasks from updated spec |
| `/spec-status` | Show spec progress and task completion |
| `/spec-validate` | Validate spec completeness and consistency |

## Usage

### Starting a New Spec

```
/spec user-authentication
```

This will:
1. Create `.claude/specs/user-authentication/` directory
2. Guide you through Requirements phase (EARS notation)
3. Guide you through Design phase (architecture docs)
4. Generate Tasks and sync to Claude Code todos

### Spec Files Location

Specs are stored in `.claude/specs/<feature-name>/`:
```
.claude/specs/user-authentication/
├── requirements.md   # User stories with acceptance criteria
├── design.md         # Architecture and implementation plan
└── tasks.md          # Trackable implementation tasks
```

## Auto-Context

When implementing features, Claude automatically includes relevant spec files as context if you're working in a directory with specs.

## EARS Notation

Requirements use EARS (Easy Approach to Requirements Syntax):

```
WHEN [condition/trigger]
THE SYSTEM SHALL [expected behavior]
```

Example:
```
WHEN a user submits invalid form data
THE SYSTEM SHALL display validation errors inline
```
