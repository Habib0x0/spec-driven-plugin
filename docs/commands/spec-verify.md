# /spec-verify

Run smoke tests against a live deployed environment to confirm the feature works in production or staging. A lightweight post-deployment check — not a full test suite, just enough to confirm the feature is alive and responding correctly.

## Usage

```
/spec-verify [spec-name] [url]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `spec-name` | No | Name of the spec to verify. Auto-detected if only one spec exists. |
| `url` | No | Target environment URL. If omitted, you are prompted to enter one. |

## What It Does

1. **Locates the spec** and reads `requirements.md` to identify acceptance criteria that can be verified via browser or HTTP.

2. **Gets the target environment** — accepts production, staging, or any custom URL. Also asks for the testing scope: full smoke test, quick health check (just verify the app loads and key routes respond), or specific requirements.

3. **Builds a smoke test plan** from the spec's acceptance criteria:
   - UI behaviors → browser navigation and interaction
   - API endpoints → HTTP requests to verify responses and status codes
   - Authentication flows → login and logout verification
   - Error handling → verify error pages and responses work

   Skips criteria that require database state manipulation, background job verification, or internal-only metrics.

4. **Runs the smoke tests** against the target URL in read-only mode. No production data is modified.

5. **Presents results** as a table of checks with PASS/FAIL status and details. Asks whether to mark as deployed, investigate failures, re-test, or switch environments.

6. **Records the verification** — appends the result to `release.md` if it exists, or creates `verification.md` in the spec directory.

## Example

```
/spec-verify user-authentication https://staging.example.com
```

## Tips

- Run immediately after deployment while the team is still paying attention to the feature.
- The quick health check takes seconds and works well as a CI/CD gate.
- If smoke tests fail, check environment variables first — missing or misconfigured env vars are the most common cause of "works locally, fails in production."
- Never let the smoke tester modify production data. The command runs in read-only mode by design.
- Re-run after infrastructure changes (DNS updates, CDN changes, scaling events) that could affect behavior.

!!!warning
    Smoke tests verify that the feature exists and responds — they are not a substitute for the full test suite or acceptance testing. Run `/spec-accept` during development; run `/spec-verify` after deployment.

## See Also

- [/spec-accept](spec-accept.md) — Full acceptance testing before release
- [/spec-release](spec-release.md) — Generate the deployment checklist that includes smoke test steps
- [/spec-retro](spec-retro.md) — Capture any post-deployment issues in the retrospective
