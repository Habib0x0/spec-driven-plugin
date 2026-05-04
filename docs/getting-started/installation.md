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

## Next steps

- Follow the [Quick start](quick-start.md) to create your first spec
- Read [Concepts](concepts.md) to understand how EARS notation and task lifecycle work
