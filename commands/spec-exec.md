---
name: spec-exec
description: Execute one spec task by running Claude in autonomous mode
allowed-tools:
  - Bash
  - Read
  - Glob
---

# /spec-exec Command

Run a single iteration of spec-driven implementation. Claude picks the highest-priority pending task, implements it, tests it, updates the spec, and commits.

## Usage

Run the script directly from your project root:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/spec-exec.sh [--spec-name <name>]
```

Or via Bash tool if invoked within Claude Code:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/spec-exec.sh --spec-name <name>
```

## Arguments

- `--spec-name <name>` - Which spec to execute against. Auto-detected if only one spec exists in `.claude/specs/`.

## What It Does

1. Reads your spec files (requirements.md, design.md, tasks.md)
2. Builds a prompt with the full spec context
3. Runs `claude --dangerously-skip-permissions` with that prompt
4. Claude implements one feature, tests it, updates the spec, and commits

## Prerequisites

- A completed spec in `.claude/specs/<name>/` with all three files
- Run `/spec <name>` first if you haven't created a spec yet
