# Spec-Driven Development Plugin

A structured workflow plugin for Claude Code that transforms feature ideas into formal specifications before implementation.

## Overview

This plugin guides you through three phases:

1. **Requirements** - User stories with EARS notation and acceptance criteria
2. **Design** - Technical architecture, sequence diagrams, implementation considerations
3. **Tasks** - Discrete, trackable implementation items synced to Claude Code todos

## Commands

| Command | Description |
|---------|-------------|
| `/spec-brainstorm` | Brainstorm a feature idea (optionally with domain expert consultants) |
| `/spec <feature-name>` | Start a new spec with interactive 3-phase workflow |
| `/spec-import` | Import a markdown/PRD file and convert to EARS requirements |
| `/spec-refine` | Refine requirements/design for current spec |
| `/spec-tasks` | Regenerate tasks from updated spec |
| `/spec-status` | Show spec progress, task completion, and dependency status |
| `/spec-sync` | Sync tasks.md status back to Claude Code task list |
| `/spec-validate` | Validate spec completeness and consistency |
| `/spec-exec` | Run one autonomous implementation iteration |
| `/spec-loop` | Loop implementation until all tasks complete |
| `/spec-team` | Execute with agent team (4 specialized agents) |
| `/spec-accept` | Run user acceptance testing for formal sign-off |
| `/spec-docs` | Generate documentation from spec and implementation |
| `/spec-release` | Generate release notes and deployment checklist |
| `/spec-verify` | Run post-deployment smoke tests |
| `/spec-retro` | Run a retrospective on a completed spec |

## Usage

### Starting a New Spec

```
/spec user-authentication
```

This will:
1. Create `.claude/specs/user-authentication/` directory
2. Gather requirements interactively (2-3 rounds of questions)
3. Guide you through Design phase (architecture docs)
4. Generate Tasks and sync to Claude Code todos

### Importing from an Existing PRD

```
/spec-import my-feature --file /path/to/prd.md
```

Reads a markdown document (PRD, RFC, design doc) and converts it to EARS requirements. Review the output, then proceed to design with `/spec-refine`.

### Spec Files Location

Specs are stored in `.claude/specs/<feature-name>/`:
```
.claude/specs/user-authentication/
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

## Execution

After creating a spec, run autonomous implementation:

```bash
# single task
spec-exec.sh --spec-name user-authentication

# loop until done
spec-loop.sh --spec-name user-authentication --max-iterations 20

# agent team (Implementer + Tester + Reviewer + Debugger)
spec-team.sh --spec-name user-authentication
```

Scripts live in the plugin's `scripts/` directory. If only one spec exists, `--spec-name` is auto-detected.

### Git Worktree Isolation

By default, execution scripts create a **git worktree** for each spec:

- Branch: `spec/<spec-name>`
- Path: `.claude/specs/.worktrees/<spec-name>/`
- Main branch stays clean while the spec is implemented
- Multiple specs can run in parallel on separate worktrees
- On completion, a `gh pr create` command is suggested

Use `--no-worktree` to commit directly to the current branch (v2.x behavior).

### Crash Recovery

`spec-loop.sh` and `spec-team.sh` create checkpoint commits before each iteration. If Claude crashes or exits non-zero, the branch is rolled back to the last checkpoint automatically.

### Task Sync

After running execution scripts, use `/spec-sync` to update the Claude Code task list from tasks.md. The subprocess can't call TaskUpdate directly, so this reconciliation step keeps the two in sync.

### Agent Team Mode

Use `spec-team.sh` when you need reliable verification. It spawns 4 specialized agents:
- **Implementer** -- writes code
- **Tester** -- verifies with Playwright/tests (only they can mark Verified: yes)
- **Reviewer** -- checks code quality, security, architecture (uses Opus)
- **Debugger** -- fixes issues when Tester or Reviewer reject

This costs more tokens but prevents tasks from being marked complete without real testing.

### Post-Implementation Pipeline

After all tasks are complete, run the post-implementation scripts:

```bash
# user acceptance testing (verify requirements are met)
spec-accept.sh --spec-name user-authentication

# generate documentation from spec + code
spec-docs.sh --spec-name user-authentication

# generate release notes + deployment checklist
spec-release.sh --spec-name user-authentication --version-bump minor

# create git tag + GitHub release
spec-release.sh --spec-name user-authentication --version-bump minor --release

# post-deployment smoke test against live environment
spec-verify.sh --spec-name user-authentication --url https://staging.example.com

# quick health check only
spec-verify.sh --spec-name user-authentication --url https://prod.example.com --scope quick

# retrospective analysis
spec-retro.sh --spec-name user-authentication
```

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

## Installation

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
