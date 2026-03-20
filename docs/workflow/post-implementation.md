# Post-implementation

After all tasks are verified, a series of post-implementation scripts handle the remaining stages of the software delivery lifecycle. Run them in order.

## The pipeline

```
spec-accept.sh -> spec-docs.sh -> spec-release.sh -> spec-verify.sh -> spec-retro.sh
```

Each script is independent and can be run on its own, but the order above reflects the natural flow from "did we build the right thing" through to "is it running correctly in production."

## Step 1: Acceptance testing (spec-accept.sh)

```bash
spec-accept.sh --spec-name user-authentication
```

Or via the slash command:

```
/spec-accept
```

Runs user acceptance testing (UAT) to verify the implementation satisfies every EARS acceptance criterion in `requirements.md`. This is distinct from automated test verification — acceptance testing checks that **the right thing was built**, not just that the code passes its tests.

The acceptor reads task verification status from `tasks.md` and checks:
- Every acceptance criterion traces to a verified task
- Non-functional requirements (performance, security, accessibility) are met
- No requirements were overlooked during implementation

Output: `ACCEPTED` or `REJECTED` (as `<promise>ACCEPTED</promise>` / `<promise>REJECTED</promise>`). If accepted, an `acceptance.md` file is written to the spec directory with the date, UAT report summary, and sign-off.

If rejected, the acceptor lists which criteria failed and suggests either running `/spec-refine` (if requirements need updating) or fixing the implementation.

!!!tip
    Run `/spec-accept` after `/spec-loop` or `/spec-team` completes. Some non-functional requirements (performance benchmarks, accessibility audits) are flagged as requiring manual verification — the report calls these out explicitly.

## Step 2: Documentation (spec-docs.sh)

```bash
spec-docs.sh --spec-name user-authentication
```

Or via the slash command:

```
/spec-docs
```

Generates documentation from the spec files and the implementation. Typical outputs include:

- API reference (from design.md endpoints + code)
- User guide (from requirements.md user stories)
- Architecture decision records (from design.md alternatives considered)
- Runbook (operational procedures)

## Step 3: Release (spec-release.sh)

```bash
# generate release notes and deployment checklist only
spec-release.sh --spec-name user-authentication --version-bump minor

# also create a git tag and GitHub release
spec-release.sh --spec-name user-authentication --version-bump minor --release
```

Or via the slash command:

```
/spec-release
```

Generates release notes, a changelog entry, and a deployment checklist from the spec and implementation. With `--release`, also creates a git tag and GitHub release via `gh release create`.

Version bump options: `major`, `minor`, `patch`.

## Step 4: Post-deployment verification (spec-verify.sh)

```bash
# full smoke test against staging
spec-verify.sh --spec-name user-authentication --url https://staging.example.com

# quick health check only
spec-verify.sh --spec-name user-authentication --url https://prod.example.com --scope quick
```

Or via the slash command:

```
/spec-verify
```

Runs post-deployment smoke tests against a live environment. Checks that the deployed application responds correctly based on the requirements.

Exit codes for CI/CD integration:
- `0` — all checks pass (PASS)
- `1` — one or more checks failed (FAIL)

See [CI/CD integration](../advanced/ci-cd.md) for example pipeline stages.

## Step 5: Retrospective (spec-retro.sh)

```bash
spec-retro.sh --spec-name user-authentication
```

Or via the slash command:

```
/spec-retro
```

Runs a structured retrospective on the completed spec. Reviews the full lifecycle — what went well, what was difficult, what took longer than expected, and what to do differently next time. Outputs `<promise>RETRO_COMPLETE</promise>` when finished.
