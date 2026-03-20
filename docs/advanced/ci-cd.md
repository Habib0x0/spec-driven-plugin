# CI/CD integration

The post-implementation scripts are designed to work in CI pipelines. They use exit codes and promise markers to communicate status to the calling process.

## Exit codes

| Script | Exit 0 | Exit 1 |
|--------|--------|--------|
| `spec-verify.sh` | All smoke tests pass (PASS) | One or more checks failed (FAIL) |
| `spec-loop.sh` | Completed normally (all tasks done or max iterations reached) | Unexpected error |
| `spec-accept.sh` | Script completed (check promise marker for ACCEPTED/REJECTED) | Script error |

## Promise markers

Scripts that produce structured outcomes write promise markers in their output:

| Script | Markers |
|--------|---------|
| `spec-loop.sh` | `<promise>COMPLETE</promise>` |
| `spec-accept.sh` | `<promise>ACCEPTED</promise>` or `<promise>REJECTED</promise>` |
| `spec-retro.sh` | `<promise>RETRO_COMPLETE</promise>` |

These markers let the calling script detect outcomes reliably without parsing human-readable prose.

## Example CI stages

### Post-deployment smoke test

Use `spec-verify.sh` as a deployment gate. The script exits 1 if any smoke test fails, which fails the CI step:

```bash
spec-verify.sh --spec-name user-authentication \
  --url "$STAGING_URL" \
  --scope quick || exit 1
```

For a full smoke test on staging before promoting to production:

```bash
spec-verify.sh --spec-name user-authentication \
  --url "$STAGING_URL"
```

### Acceptance gate before release

Check the promise marker from `spec-accept.sh` to gate the release stage:

```bash
output=$(spec-accept.sh --spec-name user-authentication)
if echo "$output" | grep -q '<promise>ACCEPTED</promise>'; then
  echo "Acceptance passed, proceeding to release"
else
  echo "Acceptance failed, aborting release"
  exit 1
fi
```

### Automated implementation loop in CI

Run the implementation loop in CI with a bounded iteration count. The loop exits 0 when complete or when max iterations is reached:

```bash
spec-loop.sh \
  --spec-name user-authentication \
  --max-iterations 30 \
  --no-worktree
```

!!!warning
    Running `spec-loop.sh` in CI requires `claude --dangerously-skip-permissions`, which the script uses internally. Only do this in isolated CI environments where you control what code Claude can access and execute.

## Suggested pipeline order

For a full automated pipeline after implementation:

```bash
# 1. Run acceptance testing
spec-accept.sh --spec-name "$SPEC"

# 2. Deploy to staging (your deploy step here)

# 3. Smoke test on staging
spec-verify.sh --spec-name "$SPEC" --url "$STAGING_URL" || exit 1

# 4. Generate release artifacts
spec-release.sh --spec-name "$SPEC" --version-bump minor --release

# 5. Deploy to production (your deploy step here)

# 6. Verify production
spec-verify.sh --spec-name "$SPEC" --url "$PROD_URL" --scope quick || exit 1
```

## Scope flag for spec-verify.sh

`--scope quick` runs a lightweight health check — useful for production verification where you want fast feedback without running the full test suite. The default (no `--scope` flag) runs the full smoke test battery.
