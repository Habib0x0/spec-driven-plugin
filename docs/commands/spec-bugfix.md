# /spec-bugfix

Create a structured bugfix spec for complex defects where regressions are costly. Unlike feature specs, bugfix specs start from a documented defect and work toward a surgical fix with explicit regression prevention.

## Usage

```
/spec-bugfix <bug-name>
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `bug-name` | Yes | A short, kebab-case identifier for the bugfix. Used as the directory name. |

## What It Does

1. **Documents the defect** — captures current behavior, expected behavior, and unchanged behavior using structured notation
2. **Performs root cause analysis** — explores the codebase to understand why the bug occurs
3. **Proposes a surgical fix** — minimal blast radius, explicit constraints on what not to change
4. **Generates regression-safe tasks** — reproduction test, fix implementation, regression tests, validation

## Bugfix Notation

Bugfix specs use a three-part behavior notation:

```
### Current Behavior (Defect)
WHEN a user submits a form with an email containing a plus sign
THEN the system rejects the input with "invalid email"

### Expected Behavior (Correct)
WHEN a user submits a form with an email containing a plus sign
THEN the system SHALL accept the input as valid

### Unchanged Behavior (Regression Prevention)
WHEN a user submits a form with a malformed email
THEN the system SHALL CONTINUE TO reject the input with "invalid email"
```

The `SHALL CONTINUE TO` clause is the key difference from feature specs — it explicitly documents behavior that must not change, preventing regressions.

## Example

```
/spec-bugfix email-validation-plus-sign
```

Claude will ask for reproduction steps, explore the validation code, document the defect with the three-part notation, propose a fix, and generate tasks.

## Output

Three files in `.claude/specs/<bug-name>/`:

| File | Content |
|------|---------|
| `bugfix.md` | Current, expected, and unchanged behavior; reproduction steps; constraints |
| `design.md` | Root cause analysis, proposed fix, test properties, risk assessment |
| `tasks.md` | Reproduction test, fix implementation, regression tests, validation |

## Tips

- Be explicit about constraints — what code must NOT be modified
- Document unchanged behavior carefully; this is your regression shield
- The reproduction test must fail before the fix and pass after
- Keep the fix surgical; resist refactoring surrounding code

## See Also

- [/spec](spec.md) — Feature specs (requirements-first workflow)
- [/spec-brainstorm](spec-brainstorm.md) — Explore ideas before formalizing
