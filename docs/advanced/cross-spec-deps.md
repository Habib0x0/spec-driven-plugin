# Cross-spec dependencies

Specs can declare dependencies on other specs. Execution scripts check that all declared dependencies are fully complete before starting any implementation work.

## Declaring dependencies

Add a `## Depends On` section to the spec's `requirements.md`:

```markdown
## Depends On

- auth-system
- database-migrations
```

List one dependency per line as a bullet. Each entry is the name of another spec in `.claude/specs/`.

Remove the section entirely if the spec has no dependencies.

## What "complete" means

A dependency is considered complete when every task in its `tasks.md` satisfies all three conditions:

- `Status: completed`
- `Wired: yes` or `Wired: n/a`
- `Verified: yes`

A dependency with any task that does not meet all three conditions is considered incomplete, and the dependent spec's execution scripts will refuse to start.

## Dependency check behavior

When you run `spec-loop.sh`, `spec-exec.sh`, or `spec-team.sh`, the script calls `check_dependencies()` before creating any worktree or running any iteration.

If a dependency is not found:

```
Error: Dependency spec not found: auth-system
```

If a dependency has no `tasks.md`:

```
Error: Dependency auth-system has no tasks.md
```

If a dependency is incomplete:

```
Error: Dependency incomplete: auth-system (4/7 tasks verified)
```

The script exits with code 1. Fix or complete the dependency before running the dependent spec.

## Circular dependency detection

The scripts detect circular dependencies using a depth-first search before checking completion status. If a cycle is found, the script exits immediately with an error:

```
Error: Circular dependency detected: spec-a -> spec-b -> spec-a
```

Circular dependencies cannot be resolved automatically — you need to restructure your specs to break the cycle.

## Viewing dependency status

Use `/spec-status` to see the dependency status for the current spec:

```
Dependencies:
  auth-system: complete (7/7 tasks verified)
  database-migrations: incomplete (3/5 tasks verified)
```

This output comes from `get_dependency_status()` in `scripts/lib/deps.sh`, which reads the `## Depends On` section and checks each referenced spec.

## Multiple specs in parallel

Specs without dependencies on each other can run in parallel on separate worktrees. Because each spec gets its own branch (`spec/<name>`), parallel execution does not cause conflicts.

Specs with a dependency chain must run in order: complete the dependency first, then start the dependent spec.
