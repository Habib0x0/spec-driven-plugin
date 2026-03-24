# Templates

When you run `/spec <name>`, the plugin creates spec files from templates in the `templates/` directory. These provide the initial structure for `requirements.md`, `design.md`, and `tasks.md`.

## Template variables

Templates use `{{PLACEHOLDER}}` syntax for values that the spec-planner substitutes based on your feature context. You do not interact with these directly — the agent handles substitution during the spec creation conversation.

## Customizing templates

You can modify the templates in the plugin's `templates/` directory to match your project's conventions. Changes take effect the next time you run `/spec`.

See [Extending the plugin](../advanced/extending.md) for more details.
