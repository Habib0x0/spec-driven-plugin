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
| `/spec-scan` | Explicitly trigger a full codebase scan and update project profile |
| `/spec-debug` | Diagnose and fix bugs with spec context awareness and regression tracking |
| `/spec-sync` | Sync tasks.md status back to Claude Code task list |
| `/spec-complete` | Run full post-completion pipeline (accept -> docs -> release -> retro) |

## Model Routing

The plugin automatically uses the optimal model for each phase:

| Agent | Model | Phase | Rationale |
|-------|-------|-------|-----------|
| spec-planner | Opus 4.6 | Requirements + Design | Deep reasoning for edge cases, security, architecture |
| spec-tasker | Sonnet 4.6 | Task breakdown | Fast, structured decomposition |
| spec-validator | Sonnet 4.6 | Validation | Checklist-based verification |
| spec-implementer | Sonnet 4.6 | Implementation | Writes code for tasks |
| spec-tester | Sonnet 4.6 | Testing | Verifies with Playwright/tests |
| spec-reviewer | Opus 4.6 | Review | Code quality, security, architecture |
| spec-consultant | Sonnet 4.6 | Consultation | Domain expert analysis during brainstorming (spawned by /spec-brainstorm) |
| spec-acceptor | Sonnet 4.6 | Acceptance | Requirement traceability, non-functional verification, formal sign-off |
| spec-documenter | Sonnet 4.6 | Documentation | Generates docs from spec and code |
| spec-debugger | Sonnet 4.6 | Debugging | Fixes issues when rejected |
| spec-scanner | Sonnet 4.6 | Phase 0 Scan | Fast multi-file reading; reasoning depth not critical |

The `/spec` command delegates to these agents via the Task tool. Users don't need to manually switch models.

For implementation after spec completion, Sonnet 4.6 is recommended — the spec provides all the context needed for accurate code generation.

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

### Project Profile

The project profile (`_project-profile.md`) captures codebase intelligence that agents use to wire new code correctly. Located at `.claude/specs/_project-profile.md`, it contains six sections:

1. **Stack** - Framework, language, backend, database, styling
2. **Patterns** - Detected code patterns with confidence levels (high/medium/low)
3. **Entity Registry** - Table of domain entities and their CRUD implementation status
4. **Registration Points** - Specific `file:line` locations where new artifacts must be registered
5. **Regression Markers** - Bug fixes with affected files and regression check descriptions
6. **Manual Overrides** - User-editable section preserved across rescans

The profile is auto-created on the first `/spec` run (Phase 0 auto-scan) and can be manually updated via `/spec-scan`. For large codebases or monorepos, the scanner may split profiles by domain into `_profile-<domain>.md` files with a `_profile-index.md` listing.

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
- `spec-loop.sh` - Loops until all tasks complete or max iterations reached. Supports `--no-parallel` flag to force sequential task execution and `--no-complete` to skip auto-triggering the post-completion pipeline
- `spec-complete.sh` - Full post-completion pipeline: accept -> docs -> release -> retro. Auto-triggered by `spec-loop.sh` on completion (disable with `--no-complete`)

Both scripts build a prompt from the spec files and run `claude --dangerously-skip-permissions`. The loop version re-reads spec files each iteration to pick up changes from previous runs.

Completion is detected via `<promise>COMPLETE</promise>` in Claude's output. When detected, `spec-loop.sh` automatically chains into `spec-complete.sh` which runs the full post-completion pipeline. If UAT rejects the spec, the pipeline halts.

### Post-Implementation Scripts

After all tasks are complete, these scripts handle the remaining SDLC phases (or run automatically via `spec-complete.sh`):

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
