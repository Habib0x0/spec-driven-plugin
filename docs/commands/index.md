# Command reference

All plugin commands are slash commands used within a Claude Code session. Execution scripts (`spec-loop.sh`, `spec-exec.sh`, etc.) are run from the terminal in your project root.

## Planning commands

| Command | Description | Example usage |
|---------|-------------|---------------|
| `/spec-brainstorm` | Free-form conversation to refine a vague idea before formalizing a spec. Optionally brings in domain expert consultants. | `/spec-brainstorm user notifications` |
| `/spec <name>` | Start a new spec with the three-phase workflow (Requirements, Design, Tasks). | `/spec user-authentication` |
| `/spec-refine` | Update requirements or design for the current spec. Changes cascade to design and task regeneration. | `/spec-refine` |
| `/spec-tasks` | Regenerate `tasks.md` from the current design, useful after design changes. | `/spec-tasks` |

## Status and validation commands

| Command | Description | Example usage |
|---------|-------------|---------------|
| `/spec-status` | Show current progress: task counts, completion percentages, and dependency status. | `/spec-status` |
| `/spec-validate` | Validate spec completeness and consistency: EARS notation, design coverage, task traceability, no circular dependencies. | `/spec-validate` |

## Execution commands

| Command | Description | Example usage |
|---------|-------------|---------------|
| `/spec-exec` | Run one autonomous implementation iteration: pick a task, implement, wire, test, commit. | `/spec-exec` |
| `/spec-loop` | Trigger the loop script from inside Claude Code. Runs until all tasks are verified. | `/spec-loop` |

## Post-implementation commands

| Command | Description | Example usage |
|---------|-------------|---------------|
| `/spec-accept` | Run user acceptance testing. Traces every EARS criterion to a verified task. Outputs ACCEPTED or REJECTED. | `/spec-accept` |
| `/spec-docs` | Generate documentation (API reference, user guide, runbook) from the spec and implementation. | `/spec-docs` |
| `/spec-release` | Generate release notes, changelog, and deployment checklist. Optionally creates a git tag and GitHub release. | `/spec-release` |
| `/spec-verify` | Run post-deployment smoke tests against a live URL. Exits 0 on PASS, 1 on FAIL. | `/spec-verify` |
| `/spec-retro` | Run a structured retrospective on a completed spec. | `/spec-retro` |
| `/spec-complete` | Run the full post-completion pipeline: accept → docs → release → retro. | `/spec-complete` |

## Research and navigation commands

| Command | Description | Example usage |
|---------|-------------|---------------|
| `/research` | Deep research before planning. Launches parallel agents to search docs, web, and codebase. | `/research how does our auth middleware work` |
| `/zoom-out` | Map modules, interfaces, and callers for unfamiliar code. | `/zoom-out` |
| `/ubiquitous-language` | Extract domain terms into a canonical glossary with flagged ambiguities. | `/ubiquitous-language` |

## Script equivalents

The execution and post-implementation commands also have standalone shell scripts that can be called from a terminal or CI pipeline:

| Script | Equivalent command | Notes |
|--------|--------------------|-------|
| `spec-exec.sh` | `/spec-exec` | Single iteration |
| `spec-loop.sh` | `/spec-loop` | Supports `--max-iterations`, `--progress-tail`, `--on-complete` |
| `spec-accept.sh` | `/spec-accept` | Outputs `ACCEPTED`/`REJECTED` promise markers |
| `spec-docs.sh` | `/spec-docs` | Supports `--output-dir` |
| `spec-release.sh` | `/spec-release` | Supports `--version-bump`, `--tag`, `--release` |
| `spec-verify.sh` | `/spec-verify` | Requires `--url`; supports `--scope quick`; exits 0/1 for CI |
| `spec-retro.sh` | `/spec-retro` | Outputs `RETRO_COMPLETE` promise marker |
| `spec-complete.sh` | `/spec-complete` | Full pipeline; supports `--skip-accept`, `--skip-docs`, `--skip-release`, `--skip-retro` |

Scripts live in the plugin's `scripts/` directory. If only one spec exists in `.claude/specs/`, the `--spec-name` argument is auto-detected.
