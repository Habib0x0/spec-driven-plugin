# Command reference

Commands use `/` prefix in Claude Code and `$` prefix in Codex. Execution scripts (`spec-loop.sh`, `spec-exec.sh`, etc.) are run from the terminal in your project root.

| Claude Code | Codex | Description |
|-------------|-------|-------------|
| `/spec` | `$spec` | Start a new feature spec |
| `/spec-brainstorm` | `$spec-brainstorm` | Brainstorm a feature idea |
| `/spec-bugfix` | `$spec-bugfix` | Start a bugfix spec |
| `/spec-status` | `$spec-status` | Check spec progress |

## Planning commands

| Claude Code | Codex | Description | Example |
|-------------|-------|-------------|---------|
| `/spec-brainstorm` | `$spec-brainstorm` | Brainstorm a feature idea with optional expert consultants. | `/spec-brainstorm user notifications` |
| `/spec <name>` | `$spec <name>` | Start a new feature spec (Requirements, Design, Tasks). | `/spec user-authentication` |
| `/spec-bugfix <name>` | `$spec-bugfix <name>` | Start a bugfix spec with regression prevention. | `/spec-bugfix email-validation-plus-sign` |
| `/spec-refine` | `$spec-refine` | Update requirements or design; cascades to tasks. | `/spec-refine` |
| `/spec-tasks` | `$spec-tasks` | Regenerate `tasks.md` from current design. | `/spec-tasks` |

## Status and validation commands

| Claude Code | Codex | Description | Example |
|-------------|-------|-------------|---------|
| `/spec-status` | `$spec-status` | Show progress, task counts, dependency status. | `/spec-status` |
| `/spec-validate` | `$spec-validate` | Validate EARS notation, coverage, traceability. | `/spec-validate` |

## Execution commands

| Claude Code | Codex | Description | Example |
|-------------|-------|-------------|---------|
| `/spec-exec` | `$spec-exec` | Run one implementation iteration. | `/spec-exec` |
| `/spec-loop` | `$spec-loop` | Loop until all tasks are verified. | `/spec-loop` |

## Post-implementation commands

| Claude Code | Codex | Description | Example |
|-------------|-------|-------------|---------|
| `/spec-accept` | `$spec-accept` | Acceptance testing against EARS criteria. | `/spec-accept` |
| `/spec-docs` | `$spec-docs` | Generate docs from spec and implementation. | `/spec-docs` |
| `/spec-release` | `$spec-release` | Release notes, changelog, deployment checklist. | `/spec-release` |
| `/spec-verify` | `$spec-verify` | Post-deployment smoke tests against a URL. | `/spec-verify` |
| `/spec-retro` | `$spec-retro` | Retrospective on a completed spec. | `/spec-retro` |
| `/spec-complete` | `$spec-complete` | Full pipeline: accept → docs → release → retro. | `/spec-complete` |

## Research and navigation commands

| Claude Code | Codex | Description | Example |
|-------------|-------|-------------|---------|
| `/research` | `$research` | Deep parallel research before planning. | `/research how does our auth middleware work` |
| `/zoom-out` | `$zoom-out` | Map modules, interfaces, and callers. | `/zoom-out` |
| `/ubiquitous-language` | `$ubiquitous-language` | Extract domain glossary. | `/ubiquitous-language` |

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
