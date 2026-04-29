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
| `/spec-brainstorm` | Brainstorm a feature idea before spec creation |
| `/spec <name>` | Start new spec with 3-phase workflow |
| `/spec-refine` | Update existing requirements/design |
| `/spec-tasks` | Regenerate tasks from spec |
| `/spec-status` | Show progress and task completion |
| `/spec-validate` | Validate completeness and consistency |
| `/spec-exec` | Run one autonomous implementation iteration |
| `/spec-loop` | Loop implementation until all tasks complete |
| `/spec-accept` | Run user acceptance testing for formal sign-off |
| `/spec-docs` | Generate documentation from spec and implementation |
| `/spec-release` | Generate release notes, changelog, and deployment checklist |
| `/spec-verify` | Run post-deployment smoke tests against a live environment |
| `/spec-retro` | Run a retrospective to capture lessons learned |
| `/research` | Deep research before planning — parallel agents search docs, web, and codebase |
| `/zoom-out` | Step up a layer of abstraction and map modules, interfaces, and callers |
| `/ubiquitous-language` | Extract domain terms into a canonical glossary with flagged ambiguities |

## Model Routing

The plugin routes each agent to a model tier. Claude Code resolves tier aliases (`opus`, `sonnet`, `haiku`) to the current model in that tier at runtime, so the plugin stays compatible with new model releases without code changes.

| Agent | Model Tier | Phase | Rationale |
|-------|------------|-------|-----------|
| spec-planner | opus | Requirements + Design | Deep reasoning for edge cases, security, architecture |
| spec-tasker | sonnet | Task breakdown | Fast, structured decomposition |
| spec-validator | sonnet | Validation | Checklist-based verification |
| spec-implementer | sonnet | Implementation | Writes code for tasks |
| spec-tester | sonnet | Testing | Verifies with Playwright/tests |
| spec-reviewer | opus | Review | Code quality, security, architecture |
| spec-consultant | sonnet | Consultation | Domain expert analysis during brainstorming (spawned by /spec-brainstorm) |
| spec-acceptor | sonnet | Acceptance | Requirement traceability, non-functional verification, formal sign-off |
| spec-documenter | sonnet | Documentation | Generates docs from spec and code |
| spec-scanner | sonnet | Profile scan | Detects framework, patterns, entities, registration points |
| spec-debugger | haiku | Debug / small fixes | Lightweight targeted fixes when Tester or Reviewer rejects |

The `/spec` command delegates to these agents via the Task tool. Users don't need to manually switch models.

Each agent's model can be overridden via environment variable (e.g., `SPEC_MODEL_PLANNER=my-model`). See [`docs/advanced/model-routing.md`](docs/advanced/model-routing.md) for details on per-agent overrides, non-Anthropic backend support, and router configuration examples.

For implementation after spec completion, the sonnet tier is recommended — the spec provides all the context needed for accurate code generation.

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
- `spec-loop.sh` - Loops until all tasks complete or max iterations reached. Supports `--no-complete` to skip auto-triggering the post-completion pipeline
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

## Communication Style

When a user sends a greeting (hi, hello, etc.) with no specific request, respond briefly and ask what they'd like to work on. Do NOT analyze the project or provide unsolicited information.

## UI/TUI Development

When fixing UI/visual bugs, do NOT guess from code alone. Ask the user to describe the exact visual behavior or wait for screenshot descriptions. Make minimal, targeted changes — do not refactor surrounding code.

## Config & Dotfiles

After modifying shell configs (tmux, neovim, zsh, bash), always verify the change took effect:
- Reload or source the config file explicitly
- Test a related command to confirm the change applied
- Never report success without verification
- If a reload doesn't work, diagnose before proceeding (the file may have syntax errors)

## Languages & Build

Primary languages: Rust, TypeScript, Go, Python.

When editing Rust code, run `cargo check` after changes to catch compilation errors early. When editing TypeScript, ensure `.tsx` extension for JSX files and run `npx tsc --noEmit` to validate. When editing shell scripts, use `shellcheck $FILE` to catch issues before running.

## Validation Rules

The spec-validator agent checks:
- Requirements have proper EARS notation (no vague terms like "quickly", "properly")
- Design addresses all requirements
- Tasks trace back to requirements with valid dependencies (no cycles)
- Cross-document consistency (IDs match between files)

## Error Handling and Resilience

When running spec-loops or parallel agent tasks, follow these rules to prevent unproductive loops:

### Stop Condition for Repeated Failures
- If an API error, model access error, or tool failure occurs, stop after 2 failed attempts and report clearly
- Do NOT loop retrying the same failing approach indefinitely
- When blocked, explain: (1) the exact error, (2) your hypothesis about the root cause, (3) what information/access you'd need to fix it
- If a task is fundamentally blocked (e.g., missing git remote, model unavailable), skip it and log to progress.md

### Preflight Validation Before Large Workflows
Before launching `/spec-loop` or spawning parallel agents, run these checks:
1. Verify git remote is configured (`git remote -v`)
2. Test model access with a simple prompt (5-10 words)
3. Confirm the project builds (`npm run build`, `cargo build`, etc.)
4. List any blockers or known failures

Only proceed if all checks pass. A 2-minute preflight check saves hours if the workflow fails mid-run.

### Checkpoint and Recovery for Long Runs
- When running spec-loops with 40+ tasks, use checkpoint files to track progress
- If a loop fails or rate-limits partway through, resume from the last successful checkpoint instead of starting over
- Log each iteration's progress to progress.md with clear completion markers
- Use `spec-loop.sh --max-iterations <n>` to control batch size, not to retry failed tasks indefinitely

### Configuration and Dotfile Changes
After modifying shell configs (tmux, neovim, zsh), always verify the change took effect:
- Reload or source the config file
- Test a related command to confirm the change applied
- Never report success without verification
- If a reload doesn't work, diagnose before proceeding (the file may have a syntax error)
