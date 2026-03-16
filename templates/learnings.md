# Codebase Learnings

> Discovered during implementation. Each iteration should READ this before starting
> and APPEND any new discoveries. Do NOT edit previous entries.

---

<!--
Each entry should be a single-line bullet under a category heading.
Categories: Environment, Schema, Patterns, Gotchas, Testing, Dependencies

Example:
## Gotchas
- ioredis `KEYS` command does NOT auto-prefix (unlike GET/SET/DEL) — use `${prefix}${pattern}`
- Playwright e2e tests fail if webServer is configured but app runs in Docker

## Schema
- `base_group` column is `name`, not `xml_id` — use `name` in queries

## Patterns
- All services use factory pattern, not direct instantiation
- Frontend API calls go through `api.ts` wrapper, never raw fetch
-->
