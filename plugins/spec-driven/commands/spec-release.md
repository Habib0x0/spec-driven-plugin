---
name: spec-release
description: Generate release notes, changelog, and deployment checklist
argument-hint: "[spec-name]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# /spec-release Command

Prepare a feature for release by generating changelog entries, migration checklists, environment variable documentation, and deployment steps. Optionally creates a git tag and GitHub release.

## Philosophy

The gap between "all tasks complete" and "shipped" is where things break. This command makes deployment preparation systematic — no forgotten migrations, missing env vars, or undocumented breaking changes.

## Workflow

### 1. Locate the Spec

If a spec name is provided, use it. Otherwise auto-detect from `.claude/specs/`.

### 2. Gather Release Context

Read the spec files and codebase to collect:

**From `tasks.md`:**
- All completed tasks (these become changelog items)
- Task descriptions and requirement tracebacks

**From `design.md`:**
- Data model changes (migrations needed?)
- New environment variables
- External service dependencies
- Breaking changes to existing APIs

**From `requirements.md`:**
- User-facing changes (for user-facing changelog)
- Non-functional changes (for ops changelog)

**From `acceptance.md`** (if exists, from `/spec-accept`):
- Acceptance status and any conditions

**From git log:**
- All commits related to this feature (scan for spec name or task IDs)
- Authors who contributed

### 3. Ask Release Configuration

Use AskUserQuestion:

**Version bump type:**
- **Patch** (bug fix, no breaking changes)
- **Minor** (new feature, backwards compatible)
- **Major** (breaking changes)

**Release scope:**
- **Full release** — Changelog, deployment checklist, env vars, migrations
- **Changelog only** — Just the changelog entry
- **Deployment checklist only** — Just the ops checklist

### 4. Generate Release Artifacts

Write to `.claude/specs/<feature-name>/release.md`:

```markdown
## Release: [Feature Name]

### Version
[version bump type] — [rationale]

### Release Date
[current date]

### Changelog

#### User-Facing Changes
- [Change derived from user stories — written for end users]
- [Another change]

#### Technical Changes
- [Change derived from tasks — written for developers]
- [Another change]

#### Breaking Changes
- [Any breaking changes from design.md — with migration path]

### Deployment Checklist

#### Pre-Deployment
- [ ] Database migrations applied: [list specific migrations]
- [ ] Environment variables set: [list with descriptions]
- [ ] External services configured: [list dependencies]
- [ ] Feature flags configured: [if applicable]
- [ ] Rollback plan reviewed

#### Deployment
- [ ] Deploy to staging
- [ ] Run smoke tests on staging (see /spec-verify)
- [ ] Deploy to production
- [ ] Run smoke tests on production

#### Post-Deployment
- [ ] Verify health checks pass
- [ ] Monitor error rates for 30 minutes
- [ ] Notify stakeholders
- [ ] Update documentation (see /spec-docs)

### Environment Variables
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| [VAR_NAME] | Yes/No | [default] | [purpose] |

### Database Migrations
[List of schema changes with migration commands, or "No migrations required"]

### Rollback Plan
[Steps to revert this release if issues are found]

### Contributors
[From git log — authors who committed to this feature]
```

### 5. Optional: Create Git Tag and GitHub Release

Ask the user via AskUserQuestion:
- **Create git tag** — Tag the current commit with the version
- **Create GitHub release** — Create a release on GitHub with the changelog
- **Both** — Tag + release
- **Skip** — Just keep the release.md artifact

If they choose to create a tag/release, use Bash to run:
```bash
git tag -a v[version] -m "[feature-name] release"
gh release create v[version] --title "[Feature Name]" --notes-file .claude/specs/<feature-name>/release.md
```

### 6. Summary

Present:
- The release artifact location
- Key items from the deployment checklist
- Any breaking changes that need attention
- Suggested next steps: `/spec-verify` for post-deployment smoke testing

## Tips

- Run after `/spec-accept` to include acceptance status in the release
- The deployment checklist is a safety net — customize it for your team's process
- Breaking changes should include migration paths, not just "this changed"
- The rollback plan is critical — think about it before you need it
- For hotfixes, the "Changelog only" scope keeps things fast
