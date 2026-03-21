# Quick start

This guide walks through creating a spec from scratch and running the first implementation iteration.

## Step 1: Start a new spec

Run the `/spec` command with a feature name:

```
/spec user-authentication
```

The spec-planner agent (Opus 4.6) will ask if you want to start from a preset template or from scratch. For a new authentication feature, you might choose the preset to get pre-filled user stories covering common scenarios.

The agent then guides you through two phases interactively:

1. **Requirements** — It asks clarifying questions, identifies user roles, and writes user stories with EARS acceptance criteria
2. **Design** — It defines the architecture, data models, and key sequences based on your requirements

After both phases, it generates a `tasks.md` file and syncs the tasks to Claude Code's todo list.

Your spec files are created at:

```
.claude/specs/user-authentication/
├── requirements.md
├── design.md
└── tasks.md
```

## Step 2: Check the spec status

Before running implementation, review what was created:

```
/spec-status
```

This shows task completion, dependency status, and which tasks are pending, in progress, or verified.

## Step 3: Run the first implementation iteration

Run one autonomous implementation cycle:

```
/spec-exec
```

The agent picks the highest-priority pending task, implements it, verifies it, updates `tasks.md`, and commits. Run it again for the next task, or use `/spec-loop` to run all tasks automatically.

!!!tip
    If you have only one spec in `.claude/specs/`, the `--spec-name` argument is auto-detected. With multiple specs, pass `--spec-name <name>` explicitly.

## Step 4: Run all remaining tasks automatically

To let the plugin work through all remaining tasks without manual intervention:

```bash
spec-loop.sh --spec-name user-authentication --max-iterations 20
```

The loop checks for the `<promise>COMPLETE</promise>` marker in Claude's output and stops when all tasks are verified. See [Execution](../workflow/execution.md) for details on the three execution modes.

## Step 5: Post-implementation

Once all tasks are complete, run the post-implementation pipeline:

```bash
spec-accept.sh --spec-name user-authentication
spec-docs.sh --spec-name user-authentication
spec-release.sh --spec-name user-authentication --version-bump minor
```

See [Post-implementation](../workflow/post-implementation.md) for the full pipeline.

## What's next

- Read [Workflow overview](../workflow/overview.md) to understand the full lifecycle
- See [Commands](../commands/index.md) for all available commands
- Read [Concepts](concepts.md) for a deeper explanation of EARS notation and task lifecycle
