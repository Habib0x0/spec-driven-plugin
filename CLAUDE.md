# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Claude Code plugin that provides spec-driven development workflows. It guides feature development through three phases: Requirements (EARS notation), Design (architecture), and Tasks (trackable implementation items).

## Plugin Structure

```
.claude-plugin/plugin.json  - Plugin manifest (name, version, metadata)
commands/                   - Slash command definitions
scripts/                    - Standalone execution scripts (spec-exec, spec-loop)
skills/spec-workflow/       - Main skill with reference docs
agents/                     - Subagent definitions
templates/                  - Document scaffolding for specs
```

## Commands

| Command | Purpose |
|---------|---------|
| `/spec-brainstorm` | Brainstorm a feature idea (optionally with domain expert consultants) |
| `/spec <name>` | Start new spec with 3-phase workflow |
| `/spec-refine` | Update existing requirements/design |
| `/spec-tasks` | Regenerate tasks from spec |
| `/spec-status` | Show progress and task completion |
| `/spec-validate` | Validate completeness and consistency |
| `/spec-exec` | Run one autonomous implementation iteration |
| `/spec-loop` | Loop implementation until all tasks complete |
| `/spec-team` | Execute with agent team (Implementer + Tester + Reviewer + Debugger) |
| `/spec-accept` | Run user acceptance testing for formal sign-off |
| `/spec-docs` | Generate documentation from spec and implementation |
| `/spec-release` | Generate release notes, changelog, and deployment checklist |
| `/spec-verify` | Run post-deployment smoke tests against a live environment |
| `/spec-retro` | Run a retrospective to capture lessons learned |

## Model Routing

The plugin automatically uses the optimal model for each phase:

| Agent | Model | Phase | Rationale |
|-------|-------|-------|-----------|
| spec-planner | Opus 4.6 | Requirements + Design | Deep reasoning for edge cases, security, architecture |
| spec-tasker | Sonnet | Task breakdown | Fast, structured decomposition |
| spec-validator | Sonnet | Validation | Checklist-based verification |
| spec-implementer | Sonnet | Implementation | Writes code for tasks |
| spec-tester | Sonnet | Testing | Verifies with Playwright/tests |
| spec-reviewer | Opus | Review | Code quality, security, architecture |
| spec-consultant | Sonnet | Consultation | Domain expert analysis during brainstorming (spawned by /spec-brainstorm) |
| spec-acceptor | Sonnet | Acceptance | Requirement traceability, non-functional verification, formal sign-off |
| spec-documenter | Sonnet | Documentation | Generates docs from spec and code |
| spec-debugger | Sonnet | Debugging | Fixes issues when rejected |

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

## Execution Mode

After completing the spec workflow (Requirements, Design, Tasks), use the execution scripts to implement autonomously:

- `spec-exec.sh` - Single iteration: implements one task, tests, updates spec, commits
- `spec-loop.sh` - Loops until all tasks complete or max iterations reached

Both scripts build a prompt from the spec files and run `claude --dangerously-skip-permissions`. The loop version re-reads spec files each iteration to pick up changes from previous runs.

Completion is detected via `<promise>COMPLETE</promise>` in Claude's output.

### Post-Implementation Scripts

After all tasks are complete, these scripts handle the remaining SDLC phases:

- `spec-accept.sh` - User acceptance testing against requirements (outputs `ACCEPTED`/`REJECTED`)
- `spec-docs.sh` - Generate documentation from spec + code (API ref, user guide, ADR, runbook)
- `spec-release.sh` - Release notes, changelog, deployment checklist; optional `--tag` and `--release`
- `spec-verify.sh` - Post-deployment smoke test against a live URL (exits 0/1 for CI/CD)
- `spec-retro.sh` - Retrospective analysis of a completed spec; accepts `--spec-name <name>` (outputs `RETRO_COMPLETE`)

## Validation Rules

The spec-validator agent checks:
- Requirements have proper EARS notation (no vague terms like "quickly", "properly")
- Design addresses all requirements
- Tasks trace back to requirements with valid dependencies (no cycles)
- Cross-document consistency (IDs match between files)
