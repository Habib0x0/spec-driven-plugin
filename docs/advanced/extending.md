# Extending the plugin

The plugin is designed to be extended. You can add new commands, agents, and templates without modifying the core skill.

## Plugin structure

```
.claude-plugin/plugin.json   -- plugin manifest (name, version, metadata)
commands/                    -- slash command definitions
scripts/                     -- standalone execution scripts
scripts/lib/                 -- shared bash libraries (worktree, checkpoint, deps)
skills/spec-workflow/        -- main skill and reference docs
skills/spec-workflow/references/  -- supplementary reference documents
agents/                      -- subagent definitions
templates/                   -- document scaffolding
```

## Adding a command

Create a new `.md` file in `commands/` with YAML frontmatter:

```yaml
---
name: spec-mycommand
description: Short description shown in command picker
argument-hint: "[optional-argument]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Task
---

# /spec-mycommand Command

Command body — this is what Claude reads when the command is invoked.
```

The `name` field must match the filename (without `.md`). The `allowed-tools` list controls which Claude Code tools the command can use.

After adding a command file, restart Claude Code for it to appear.

## Adding an agent

Create a new `.md` file in `agents/` with YAML frontmatter:

```yaml
---
name: spec-myagent
model: sonnet
description: What this agent does
allowed-tools:
  - Read
  - Write
---

# Agent system prompt

The agent's instructions go here.
```

Agents are spawned by commands via the `Task` tool. Reference the agent by its fully qualified name: `spec-driven:spec-myagent`.

Model options: `sonnet` (default for most agents), `opus` (for deep reasoning tasks like planning and review).

## Adding reference material

Place supplementary documentation in `skills/spec-workflow/references/`. The main skill file (`SKILL.md`) references these by relative path. Reference files are loaded by agents when they need detailed guidance on a specific topic.

Existing reference files:
- `ears-notation.md` — EARS pattern reference with examples
- `design-patterns.md` — architecture documentation patterns
- `task-breakdown.md` — task decomposition strategies

## Template variables

Templates use `{{PLACEHOLDER}}` markers that the spec-planner replaces during spec creation. Common placeholders:

| Placeholder | Description |
|-------------|-------------|
| `{{FEATURE_NAME}}` | The feature name passed to `/spec` |

The spec-planner handles substitution — users do not interact with placeholders directly.

## Modifying reference documents

Reference documents in `skills/spec-workflow/references/` are loaded on demand by agents. You can add new sections, examples, or patterns to any reference file. Changes take effect immediately without restarting Claude Code.

If you add a new reference file, update `SKILL.md` to reference it in the "Additional Resources" section so agents know it exists.
