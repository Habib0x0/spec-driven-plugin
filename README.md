# Spec-Driven Development Plugin

A structured workflow plugin for Codex and Claude Code that transforms feature ideas into formal specifications before implementation.

## Overview

This plugin guides you through three phases:

1. **Requirements** - User stories with EARS notation and acceptance criteria
2. **Design** - Technical architecture, sequence diagrams, implementation considerations
3. **Tasks** - Discrete, trackable implementation items that can be mirrored to the active agent's todo system

## Commands

### Core Workflow
| Command | Description |
|---------|-------------|
| `/spec-brainstorm` | Brainstorm a feature idea before spec creation |
| `/spec <feature-name>` | Start a new spec with interactive 3-phase workflow |
| `/spec-refine` | Refine requirements/design for current spec |
| `/spec-tasks` | Regenerate tasks from updated spec |
| `/spec-status` | Show spec progress, task completion, and dependency status |
| `/spec-validate` | Validate spec completeness and consistency |

### Implementation
| Command | Description |
|---------|-------------|
| `/spec-exec` | Run one autonomous implementation iteration |
| `/spec-loop` | Loop implementation until all tasks complete |

### Post-Completion (Optional)
| Command | Description |
|---------|-------------|
| `/spec-accept` | Run user acceptance testing for formal sign-off |
| `/spec-docs` | Generate documentation from spec and implementation |
| `/spec-release` | Generate release notes and deployment checklist |
| `/spec-verify` | Run post-deployment smoke tests |
| `/spec-retro` | Run a retrospective on a completed spec |
| `/spec-complete` | Run full post-completion pipeline (accept → docs → release → retro) |

## Usage

### Starting a New Spec

```
/spec user-authentication
```

This will:
1. Create `.codex/specs/user-authentication/` directory
2. Gather requirements interactively (2-3 rounds of questions)
3. Guide you through Design phase (architecture docs)
4. Generate Tasks with explicit status, wiring, verification, and dependencies


### Spec Files Location

Specs are stored in `.codex/specs/<feature-name>/` by default. Existing `.claude/specs/<feature-name>/` directories are still supported as a migration fallback, or you can set `SPEC_ROOT` explicitly:
```
.codex/specs/user-authentication/
├── requirements.md   # User stories with acceptance criteria
├── design.md         # Architecture and implementation plan
└── tasks.md          # Trackable implementation tasks
```

### Cross-Spec Dependencies

Specs can declare dependencies on other specs via a `## Depends On` section in requirements.md:

```markdown
## Depends On

- auth-system
- database-migrations
```

Execution scripts check dependencies before running. A dependency is considered complete when all its tasks are verified. `/spec-status` shows dependency status.

## Implementation

After creating a spec, run autonomous implementation:

```bash
# single task
bash scripts/spec-exec.sh --spec-name user-authentication

# loop until all tasks complete
bash scripts/spec-loop.sh --spec-name user-authentication --max-iterations 20
```

Scripts live in the plugin's `scripts/` directory. If only one spec exists, `--spec-name` is auto-detected.

### Post-Completion (Optional)

After implementation completes, optionally run:

```bash
# user acceptance testing
bash scripts/spec-accept.sh --spec-name user-authentication

# generate documentation
bash scripts/spec-docs.sh --spec-name user-authentication

# release notes and deployment checklist
bash scripts/spec-release.sh --spec-name user-authentication

# post-deployment smoke tests
bash scripts/spec-verify.sh --spec-name user-authentication

# retrospective analysis
bash scripts/spec-retro.sh --spec-name user-authentication

# or run all at once
bash scripts/spec-complete.sh --spec-name user-authentication
```

### Git Worktree Isolation

By default, execution scripts create a **git worktree** for each spec:

- Branch: `spec/<spec-name>`
- Path: `.codex/specs/.worktrees/<spec-name>/`
- Main branch stays clean while the spec is implemented
- Multiple specs can run in parallel on separate worktrees
- On completion, a `gh pr create` command is suggested

Use `--no-worktree` to commit directly to the current branch (v2.x behavior).

### Checkpoint Recovery

`spec-loop.sh` creates checkpoint commits before each iteration. If the agent crashes or exits non-zero, the branch is rolled back to the last checkpoint automatically.

### CI/CD Integration

The verification script returns exit codes for CI pipelines:
- `spec-verify.sh` exits `0` on PASS, `1` on FAIL
- `spec-accept.sh` outputs `<promise>ACCEPTED</promise>` or `<promise>REJECTED</promise>`

Example CI stage:
```bash
spec-verify.sh --url "$STAGING_URL" --scope quick || exit 1
```

## Spec-Loop Performance

The loop script includes optimizations for long-running specs:
- **Progress tail**: Only the last 20 progress entries are included in the prompt (configurable via `--progress-tail`)
- **Lightweight Step 1**: Iterations 2+ skip full environment checks
- **Spec reference**: Requirements and design are referenced by path (not inlined) after iteration 1
- **Timing**: Each iteration prints elapsed time

## Auto-Context

When implementing features, include relevant spec files as context if you're working in a directory with specs.

## Reference Documentation

For advanced workflows and optimization patterns, see:

- **REPORT_ENHANCEMENTS.md** — What changed from v4.x to v5.0 and why (breaking changes overview)
- **ADVANCED_PATTERNS.md** — Power user patterns:
  - Test-driven autonomous loops
  - Parallel agent teams
  - Checkpoint-based pipelines
  - Error loop prevention
- **HEADLESS_ORCHESTRATION.md** — Alternative parallel execution approach for large specs

These are reference materials. The core workflow (spec → exec/loop) works for all project sizes.

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

## Installation

### Codex

This repository now includes a Codex plugin manifest at `.codex-plugin/plugin.json` and marketplace metadata at `.agents/plugins/marketplace.json`.

Install from GitHub:

```bash
codex plugin marketplace add Habib0x0/spec-driven-plugin
```

Or test the local checkout:

```bash
codex plugin marketplace add /path/to/spec-driven-plugin
```

The execution scripts default to Codex when `codex` is available:

```bash
export SPEC_AGENT_BACKEND=codex
bash scripts/spec-exec.sh --spec-name user-authentication
```

Useful overrides:

```bash
export SPEC_ROOT=.codex/specs
export SPEC_AGENT_CMD='codex exec --full-auto -'
```

### Claude Code

Add to your `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "spec-driven@spec-driven": true
  },
  "extraKnownMarketplaces": {
    "spec-driven": {
      "source": {
        "source": "url",
        "url": "https://github.com/Habib0x0/spec-driven-plugin.git"
      }
    }
  }
}
```

Then restart Claude Code.

## Inspiration

This plugin was inspired by [Kiro](https://kiro.dev)'s spec-driven development functionality. Kiro introduced the concept of structured specification workflows that guide developers through requirements gathering, design, and task breakdown before implementation.

Key concepts borrowed from Kiro:
- **Three-phase workflow**: Requirements -> Design -> Tasks
- **EARS notation**: Structured acceptance criteria format
- **Spec file organization**: Dedicated spec directories with separate documents for each phase
- **Task traceability**: Linking implementation tasks back to requirements

## License

MIT
