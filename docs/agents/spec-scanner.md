# spec-scanner

The spec-scanner analyzes an existing codebase and produces a **project profile** — a structured summary of the tech stack, detected patterns, domain entities, and registration points. Other agents read this profile to generate wiring-aware specs and code.

## Role

Scan the codebase on first `/spec` invocation (Phase 0), detect what the project is built on, and record that intelligence in `.claude/specs/_project-profile.md` (or split files for large monorepos). The profile lives in the repo and is reused by subsequent agents.

## Model

**sonnet tier.** The scanner reads many files and extracts structural information. Depth of reasoning matters less than throughput — the sonnet tier is the right fit for fast, accurate pattern detection.

## When It Runs

- `/spec <name>` — Phase 0 auto-scan on first invocation if no profile exists
- `/spec-scan` — manual rescan to refresh the profile after significant codebase changes

## What It Records

The project profile captures six sections:

1. **Stack** — Framework, language, backend, database, styling system.
2. **Patterns** — Detected conventions with confidence levels (high/medium/low). The planner and tasker prefer high-confidence patterns when generating specs.
3. **Entity Registry** — Domain entities and their CRUD implementation status, used for gap analysis during requirements.
4. **Registration Points** — Specific `file:line` locations where new artifacts (routes, components, migrations) must be registered so the implementer doesn't produce orphaned code.
5. **Regression Markers** — Prior bug fixes and the files they touched, so reviewers know which areas are regression-prone.
6. **Manual Overrides** — User-editable section preserved across rescans.

Output: `.claude/specs/_project-profile.md` (single-file) or `_profile-index.md` + `_profile-<domain>.md` files (split for large monorepos).

## Key Rules

- Never reads credential-bearing files (`.env`, `~/.aws`, `~/.ssh`, etc.). The scanner has an explicit skip list.
- Confidence levels on patterns are not guesses — they reflect how consistently the pattern appears in the scanned code.
- The Manual Overrides section is preserved across rescans. Users can pin conventions that the scanner can't detect automatically.
- For large codebases, the scanner splits the profile by domain to keep each file readable.
