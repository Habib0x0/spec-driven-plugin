# Installation

The plugin is installed by adding it to your Claude Code settings file.

## Prerequisites

- Claude Code installed and configured
- A GitHub account (the plugin is hosted on GitHub)

## Add the plugin

Open (or create) `~/.claude/settings.json` and add the following:

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

Restart Claude Code after saving the file.

## Verify the installation

After restarting, type `/spec` in a Claude Code session. If the plugin is installed correctly, you will see the spec command activate.

## Codex

The plugin also works with Codex via the manifest at `.codex-plugin/plugin.json`.

### Install in Codex

```bash
codex plugin marketplace add Habib0x0/spec-driven-plugin
```

### Command Syntax

Codex commands use `$spec-driven:` prefix instead of `/`:

| Claude Code | Codex |
|-------------|-------|
| `/spec <name>` | `$spec-driven:spec <name>` |
| `/spec-brainstorm` | `$spec-driven:spec-brainstorm` |
| `/spec-bugfix <name>` | `$spec-driven:spec-bugfix <name>` |
| `/spec-status` | `$spec-driven:spec-status` |
| `/spec-exec` | `$spec-driven:spec-exec` |
| `/spec-loop` | `$spec-driven:spec-loop` |

### Usage in Codex

Invoke the skill by typing one of its default prompts:

| Prompt | Action |
| --- | --- |
| `Create a spec for this feature` | Start a new spec workflow |
| `Validate the current spec` | Run validation on the active spec |
| `Break this design into tasks` | Regenerate tasks from the design doc |

You can also reference the skill by its display name, e.g. `Use Spec Driven to plan user authentication`.

Under Codex, spec files are written to `.codex/specs/<feature-name>/`.

### Plan Mode vs Build Mode

Codex supports two execution modes. The plugin works in both:

**Plan Mode (`codex --plan`)**

- The agent generates the full spec content (requirements, design, tasks)
- Codex presents it as a plan for review — no files are written yet
- Review the spec, then approve to apply it in build mode
- Use this when you want to see what the spec would look like before committing

**Build Mode (`codex` default)**

- The agent generates and writes spec files directly to `.codex/specs/`
- Implementation scripts (`spec-exec.sh`, `spec-loop.sh`) must be run from your terminal, not inside Codex
- Use this when you want the spec created immediately and are ready to implement

**Key differences from Claude Code:**

| Feature | Claude Code | Codex |
|---------|-------------|-------|
| Spec generation | Writes files directly | Writes files in build mode; plans in plan mode |
| Task sync | Syncs to Claude Code todo system | No native todo sync; tasks live in `tasks.md` |
| Execution | `/spec-exec` and `/spec-loop` slash commands | Run `spec-exec.sh` / `spec-loop.sh` from terminal |
| Spec directory | `.claude/specs/` | `.codex/specs/` |

## Next steps

- Follow the [Quick start](quick-start.md) to create your first spec
- Read [Concepts](concepts.md) to understand how EARS notation and task lifecycle work
