# /spec-release

Prepare a feature for release. Generates a changelog entry, deployment checklist, environment variable documentation, migration steps, and rollback plan. Optionally creates a git tag and GitHub release.

## Usage

```
/spec-release [spec-name]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `spec-name` | No | Name of the spec to release. Auto-detected if only one spec exists. |

## What It Does

1. **Locates the spec** and reads all spec files, git history, and the `acceptance.md` file if one exists from `/spec-accept`.

2. **Gathers release context** from the spec:
   - Completed tasks (become changelog items)
   - Data model changes from `design.md` (database migrations needed?)
   - New environment variables and external service dependencies
   - Breaking changes to existing APIs
   - User-facing vs. technical changes

3. **Asks for release configuration:**
   - Version bump type: Patch (bug fix), Minor (new feature), or Major (breaking changes)
   - Scope: full release artifact, changelog only, or deployment checklist only

4. **Generates `release.md`** in the spec directory containing:
   - User-facing and technical changelog entries
   - Breaking changes with migration paths
   - Pre-deployment checklist (migrations, env vars, feature flags, external services)
   - Deployment steps (staging, smoke tests, production)
   - Post-deployment checklist (health checks, monitoring, stakeholder notification)
   - Environment variable table
   - Database migration commands
   - Rollback plan

5. **Optionally creates a git tag and GitHub release** using the generated changelog as release notes.

## Example

```
/spec-release user-authentication
```

## Tips

- Run this after `/spec-accept` so the acceptance status is included in the release artifact.
- The deployment checklist is a safety net — customize it for your team's specific process.
- Breaking changes must include migration paths, not just a description of what changed.
- Write the rollback plan before you need it. Review it while the feature is fresh.
- For hotfixes, use "Changelog only" scope to move fast.
- The generated `release.md` is a living checklist — check items off as you deploy.

!!!warning
    Review the deployment checklist carefully before deploying. Missing migrations, unconfigured environment variables, or skipped rollback planning are the most common causes of deployment failures.

## See Also

- [/spec-accept](spec-accept.md) — Run acceptance testing before generating a release
- [/spec-verify](spec-verify.md) — Smoke-test the live environment after deployment
- [/spec-docs](spec-docs.md) — Generate user-facing documentation alongside the release
