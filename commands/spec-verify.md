---
name: spec-verify
description: Run post-deployment smoke tests against a live environment
argument-hint: "[spec-name] [url]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - AskUserQuestion
  - Task
---

# /spec-verify Command

Run smoke tests against a deployed environment to verify the feature works in production/staging. Reuses the spec-tester agent with a target URL instead of localhost.

## Philosophy

"It works on my machine" doesn't count. Post-deployment verification catches environment-specific issues: missing env vars, CORS misconfigs, database connectivity, CDN caching, etc. This is a lightweight check, not a full test suite — just enough to confirm the feature is alive.

## Workflow

### 1. Locate the Spec

If a spec name is provided, use it. Otherwise auto-detect from `.claude/specs/`.

### 2. Get the Target Environment

If a URL was provided as a second argument, use it. Otherwise, ask via AskUserQuestion:

- **Production** — Enter the production URL
- **Staging** — Enter the staging URL
- **Custom environment** — Enter any URL

Also ask:
- **Full smoke test** — Verify all acceptance criteria that can be tested via browser
- **Quick health check** — Just verify the app loads and key routes respond
- **Specific requirements** — Pick which requirements to verify

### 3. Build the Smoke Test Plan

Read `requirements.md` and extract acceptance criteria that can be verified via browser/HTTP:

- UI behaviors → Playwright navigation and interaction
- API endpoints → HTTP requests to verify responses
- Authentication flows → Login/logout verification
- Error handling → Verify error pages/responses work

Skip criteria that require:
- Database state manipulation (unless safe read-only checks)
- Background job verification
- Internal-only metrics

### 4. Spawn the Tester Agent

Delegate to the **spec-driven:spec-tester** agent via the Task tool.

Pass the agent:
- The spec directory path
- The target URL (NOT localhost)
- The testing scope (full, quick, or specific)
- Instruction to treat this as a **smoke test, not a full test suite** — verify the feature exists and responds correctly, don't test every edge case
- Instruction to **not modify any code or files** — this is read-only verification

### 5. Present Results

When the tester returns:

```markdown
## Smoke Test Report: [Feature Name] @ [URL]

### Environment
- URL: [target URL]
- Tested at: [timestamp]

### Results
| Check | Status | Details |
|-------|--------|---------|
| App loads | PASS/FAIL | [response time, status code] |
| [Key route 1] responds | PASS/FAIL | [details] |
| [Key feature 1] works | PASS/FAIL | [details] |
| ... | ... | ... |

### Summary
- Checks passed: X/Y
- Environment issues found: [list any]
- Feature verification: PASS/FAIL
```

Ask the user via AskUserQuestion:
- **All good — mark as deployed** — Update spec status
- **Issues found — investigate** — Show details, suggest fixes
- **Re-test after fixes** — Run again with same or different scope
- **Test different environment** — Switch to another URL

### 6. Record Verification

If all checks pass, append to `.claude/specs/<feature-name>/release.md` (if it exists) or create `.claude/specs/<feature-name>/verification.md`:

```markdown
## Post-Deployment Verification

### [Environment Name] — [URL]
- Verified at: [timestamp]
- Result: PASS/FAIL
- Checks: X/Y passed
- Issues: [none or list]
```

## Tips

- Run immediately after deployment while the team is still paying attention
- The quick health check takes seconds — use it as a CI/CD gate
- If smoke tests fail, check environment variables first — it's the #1 cause of "works locally, fails in prod"
- Keep the spec-tester in read-only mode — never modify production data during verification
- Schedule re-verification after infrastructure changes (DNS, CDN, scaling events)
