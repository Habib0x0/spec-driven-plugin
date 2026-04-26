---
description: Run full post-completion pipeline (accept, docs, release, retro)
---

# /spec-complete

Run the full post-completion pipeline after all spec tasks are done. Chains: UAT -> Documentation -> Release Notes -> Retrospective.

## Usage

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/spec-complete.sh [--spec-name <name>] [--skip-accept] [--skip-docs] [--skip-release] [--skip-retro]
```

## Arguments

- `--spec-name <name>` - Which spec to run the pipeline for. Auto-detected if only one spec exists.
- `--skip-accept` - Skip user acceptance testing step.
- `--skip-docs` - Skip documentation generation step.
- `--skip-release` - Skip release notes step.
- `--skip-retro` - Skip retrospective step.

## What It Does

1. **Accept** - Runs UAT against requirements. If REJECTED, pipeline halts.
2. **Docs** - Generates documentation from spec and implementation.
3. **Release** - Creates release notes, changelog, and deployment checklist.
4. **Retro** - Captures lessons learned from the development process.

## Pipeline Behavior

- If UAT rejects the spec, the pipeline stops immediately. Fix the issues and re-run.
- Docs, release, and retro failures are warnings -- the pipeline continues.
- Use `--skip-*` flags to skip individual steps if you've already run them.

## Prerequisites

- All spec tasks must be completed (run `/spec-loop` or `/spec-exec` first).
- Spec must have `requirements.md`, `design.md`, and `tasks.md`.
