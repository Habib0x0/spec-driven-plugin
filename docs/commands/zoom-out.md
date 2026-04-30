# /zoom-out

Step up a layer of abstraction and get a structural map of unfamiliar code — modules, interfaces, callers, and how they connect — without reading every line of implementation.

## Usage

```
/zoom-out
```

## What It Does

Scans the codebase using Glob, Grep, and Read to build a high-level map of:

- All relevant modules and their public interfaces
- How modules call each other (caller graph)
- Entry points and key dependency relationships
- Where things connect without diving into implementation detail

Output is a concise structural overview you can use to orient yourself before writing a spec or implementing a feature.

## When to Use

- You're about to write a spec for a feature and don't know the existing code well
- You've inherited code and need to understand the architecture quickly
- You want to know where to wire in new code before implementing it

## Example

```
/zoom-out
```

Claude maps the codebase structure and returns a summary like:

```
## Module Map

### auth/
- auth.go — Entry point; exports Middleware(), Login(), Logout()
- session.go — Session store; called by auth.go and user.go
- tokens.go — JWT generation; called by auth.go only

### user/
- user.go — CRUD for User model; calls auth/session.go
- profile.go — Profile read/update; called by api/routes.go

### api/
- routes.go — Registers all HTTP routes; imports user/, auth/, billing/
```

## See Also

- [/research](research.md) — Deep parallel research before planning
- [/spec](spec.md) — Start a spec after getting oriented
