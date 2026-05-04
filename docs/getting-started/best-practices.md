# Best Practices

Guidelines for getting the most out of spec-driven development.

## When to use each workflow

| Situation | Command | Mode |
|-----------|---------|------|
| You know the behavior but not the architecture | `/spec <name>` | Requirements-First (default) |
| You have an existing design or architecture | `/spec <name>` | Design-First (auto-detected) |
| You have a vague idea that needs exploration | `/spec-brainstorm` | Idea-first |
| You have exploratory code that needs formalizing | `/spec-brainstorm` | Code-first (vibe-to-spec) |
| You are fixing a complex bug with regression risk | `/spec-bugfix <name>` | Bug Analysis → Design → Tasks |

## Spec organization

- **One spec per feature** — keep specs focused. A spec that tries to redesign your entire app will be unwieldy.
- **Multiple specs per repo** — `.claude/specs/` can hold many specs. Use cross-spec dependencies when features build on each other.
- **Version control everything** — commit specs to git. They are living documents that evolve with the code.
- **Name specs clearly** — use kebab-case feature names (`user-authentication`, not `auth stuff`).

## Requirements

- **Be specific** — vague terms like "fast" or "easy" make acceptance criteria untestable. Use numbers: "page loads in under 200ms."
- **Cover the unhappy path** — every happy path requirement should have a corresponding error-handling criterion.
- **Document out-of-scope explicitly** — stating what you are NOT doing prevents scope creep later.

## Design

- **Let requirements drive design** — in Requirements-First mode, review every requirement before designing. In Design-First mode, ensure every design decision maps to a requirement.
- **Reference the project profile** — the spec-planner uses `_project-profile.md` to align new code with existing patterns and registration points.
- **Document alternatives** — briefly note designs you rejected and why. Future readers will thank you.

## Tasks

- **Run the loop for long specs** — `spec-loop.sh` with `--max-iterations` is safer and faster than running `/spec-exec` repeatedly for specs with 10+ tasks.
- **Validate before executing** — run `/spec-validate` after task generation. It catches traceability gaps and circular dependencies before you start coding.
- **Keep tasks traceable** — every task should link back to at least one requirement or design component.

## Iteration

- **Refine early** — if you discover a gap during implementation, use `/spec-refine` to update requirements or design, then `/spec-tasks` to regenerate affected tasks.
- **Do not hand-edit tasks.md during execution** — let `/spec-exec` and `spec-loop.sh` update statuses. Manual edits create drift between the spec and the agent's view.
- **Update tasks after design changes** — changing `design.md` without regenerating `tasks.md` leaves stale task descriptions.

## Bugfix specs

- **Be explicit about constraints** — what code must NOT be modified? Constraints prevent over-fixing.
- **Document unchanged behavior carefully** — the `SHALL CONTINUE TO` clause is your regression shield. If you skip it, you will break something.
- **Write the reproduction test first** — it must fail before the fix and pass after. If it passes before the fix, you have not reproduced the bug.

## Post-implementation

- **Accept before releasing** — `/spec-accept` traces every EARS criterion to a verified task. Do not skip this for production features.
- **Run retrospectives** — `/spec-retro` captures lessons learned. Review them before starting the next spec.

## What to avoid

- **Specs for trivial changes** — one-line fixes do not need a spec. Use your judgment.
- **Refactoring during bugfixes** — keep bugfix specs surgical. Refactor in a separate feature spec.
- **Letting specs go stale** — if the code diverges significantly from the spec, either update the spec or archive it.
