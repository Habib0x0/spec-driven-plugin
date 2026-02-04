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
| `/spec <feature-name>` | Start a new spec with interactive 3-phase workflow |
| `/spec-refine` | Refine requirements/design for current spec |
| `/spec-tasks` | Regenerate tasks from updated spec |
| `/spec-status` | Show spec progress and task completion |
| `/spec-validate` | Validate spec completeness and consistency |
| `/spec-exec` | Run one autonomous implementation iteration |
| `/spec-loop` | Loop implementation until all tasks complete |

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

## Execution

After creating a spec, run autonomous implementation:

```bash
# single task
spec-exec.sh --spec-name user-authentication

# loop until done
spec-loop.sh --spec-name user-authentication --max-iterations 20
```

Scripts live in the plugin's `scripts/` directory. If only one spec exists, `--spec-name` is auto-detected.

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
        "source": "github",
        "repo": "Habib0x0/spec-driven-plugin"
      }
    }
  }
}
```

Then restart Claude Code.

## Inspiration

This plugin was inspired by [Kiro](https://kiro.dev)'s spec-driven development functionality. Kiro introduced the concept of structured specification workflows that guide developers through requirements gathering, design, and task breakdown before implementation.

Key concepts borrowed from Kiro:
- **Three-phase workflow**: Requirements → Design → Tasks
- **EARS notation**: Structured acceptance criteria format
- **Spec file organization**: Dedicated spec directories with separate documents for each phase
- **Task traceability**: Linking implementation tasks back to requirements

## License

MIT
