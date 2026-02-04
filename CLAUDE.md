# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Claude Code plugin that provides spec-driven development workflows. It guides feature development through three phases: Requirements (EARS notation), Design (architecture), and Tasks (trackable implementation items).

## Plugin Structure

```
.claude-plugin/plugin.json  - Plugin manifest (name, version, metadata)
commands/                   - Slash command definitions
skills/spec-workflow/       - Main skill with reference docs
agents/                     - Subagent definitions
templates/                  - Document scaffolding for specs
```

## Commands

| Command | Purpose |
|---------|---------|
| `/spec <name>` | Start new spec with 3-phase workflow |
| `/spec-refine` | Update existing requirements/design |
| `/spec-tasks` | Regenerate tasks from spec |
| `/spec-status` | Show progress and task completion |
| `/spec-validate` | Validate completeness and consistency |

## Model Routing

The plugin automatically uses the optimal model for each phase:

| Agent | Model | Phase | Rationale |
|-------|-------|-------|-----------|
| spec-planner | Opus 4.5 | Requirements + Design | Deep reasoning for edge cases, security, architecture |
| spec-tasker | Sonnet | Task breakdown | Fast, structured decomposition |
| spec-validator | Sonnet | Validation | Checklist-based verification |

The `/spec` command delegates to these agents via the Task tool. Users don't need to manually switch models.

For implementation after spec completion, Sonnet is recommended — the spec provides all the context needed for accurate code generation.

## Key Concepts

### EARS Notation
All acceptance criteria use Easy Approach to Requirements Syntax:
```
WHEN [condition/trigger]
THE SYSTEM SHALL [expected behavior]
```

Variations include `WHILE` (state-driven), `IF/WHEN` (conditional), and `SHALL NOT` (negative).

### Spec File Location
Specs are created in the target project at `.claude/specs/<feature-name>/`:
- `requirements.md` - User stories with EARS acceptance criteria
- `design.md` - Architecture, components, data models
- `tasks.md` - Implementation tasks synced to Claude Code todos

### Task Synchronization
Tasks in `tasks.md` sync to Claude Code's todo system via TaskCreate/TaskUpdate. Task phases: Setup, Core Implementation, Integration, Testing, Polish.

## Developing This Plugin

### Adding Commands
Create a new `.md` file in `commands/` with YAML frontmatter:
```yaml
---
name: command-name
description: What it does
allowed-tools:
  - Read
  - Write
---
```

### Adding Reference Material
Place supplementary docs in `skills/spec-workflow/references/`. The skill file references these with relative paths.

### Template Variables
Templates use `{{PLACEHOLDER}}` syntax for substitution during spec creation.

## Validation Rules

The spec-validator agent checks:
- Requirements have proper EARS notation (no vague terms like "quickly", "properly")
- Design addresses all requirements
- Tasks trace back to requirements with valid dependencies (no cycles)
- Cross-document consistency (IDs match between files)
