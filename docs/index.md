# Spec-Driven Development Plugin

A structured workflow plugin for Claude Code that transforms feature ideas into formal specifications before implementation. It guides you through three phases — Requirements, Design, and Tasks — before writing a line of code.

## What it does

Instead of jumping straight to implementation, the plugin establishes a clear planning record:

- **Requirements** — User stories with EARS-notation acceptance criteria that define exactly what the system must do
- **Design** — Architecture, data models, API contracts, and sequence diagrams that define how it works
- **Tasks** — Discrete, trackable implementation items linked to requirements and synced to Claude Code's todo system
- **Execution** — Autonomous implementation via scripts that pick tasks, implement, test, and commit in a loop
- **Post-implementation** — Acceptance testing, documentation generation, release notes, and retrospectives

## Key features

- Three-phase planning workflow with model routing (Opus for planning, Sonnet for execution)
- EARS notation for unambiguous, testable acceptance criteria
- Git worktree isolation so each spec runs on its own branch
- Crash recovery via checkpoint commits before each iteration
- Cross-spec dependency tracking with circular dependency detection
- Post-implementation pipeline: accept, docs, release, verify, retro

## Get started

If you are new to the plugin, start here:

1. [Installation](getting-started/installation.md) — add the plugin to Claude Code
2. [Quick start](getting-started/quick-start.md) — create your first spec end-to-end
3. [Concepts](getting-started/concepts.md) — understand EARS notation, spec files, and task lifecycle

For a full command reference, see [Commands](commands/index.md).
