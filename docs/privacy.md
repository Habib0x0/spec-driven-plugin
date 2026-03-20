# Privacy Policy

**Last updated: 2026-03-20**

## Overview

The Spec-Driven Development Plugin runs entirely on your local machine. It does not collect, transmit, or store any personal data or telemetry.

## Data Handling

### What the plugin accesses

- **Local files** -- The plugin reads and writes files within your project directory, specifically under `.claude/specs/` for spec artifacts (requirements, design, tasks, progress logs).
- **Git repository** -- The plugin uses git commands to create worktrees, branches, and commits within your local repository.
- **Claude CLI** -- The plugin invokes the `claude` CLI for autonomous execution. All interactions with the Claude API are handled by the Claude CLI itself, subject to Anthropic's privacy policy.

### What the plugin does NOT do

- Does not collect analytics or telemetry
- Does not phone home or make network requests (other than through the Claude CLI)
- Does not access files outside your project directory
- Does not store data outside your project directory (except git worktrees under `.claude/specs/.worktrees/`)
- Does not read or access credential files, environment variables, or secrets
- Does not send your code or spec contents to any third-party service

## Third-Party Services

The plugin delegates to the Claude CLI for AI-powered tasks (requirements writing, code generation, testing). These interactions are governed by [Anthropic's Privacy Policy](https://www.anthropic.com/privacy) and your Claude account terms.

The optional `gh pr create` suggestion uses the GitHub CLI, which is governed by [GitHub's Privacy Statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement).

## Data Storage

All plugin-generated data is stored locally in your project:

| Data | Location | Purpose |
|------|----------|---------|
| Spec files | `.claude/specs/<name>/` | Requirements, design, tasks |
| Progress logs | `.claude/specs/<name>/progress.md` | Session history |
| Worktrees | `.claude/specs/.worktrees/` | Isolated implementation branches |
| Generated docs | `.claude/specs/<name>/docs/` | API refs, user guides |

No data is stored outside your project directory or transmitted externally by the plugin.

## Changes to This Policy

Updates to this policy will be reflected in this file with an updated date. Check the [git history](https://github.com/Habib0x0/spec-driven-plugin/commits/main/PRIVACY.md) for changes.

## Contact

For questions about this privacy policy, open an issue at [github.com/Habib0x0/spec-driven-plugin](https://github.com/Habib0x0/spec-driven-plugin/issues).
