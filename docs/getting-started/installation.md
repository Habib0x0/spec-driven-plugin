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

## Next steps

- Follow the [Quick start](quick-start.md) to create your first spec
- Read [Concepts](concepts.md) to understand how EARS notation and task lifecycle work
