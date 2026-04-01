---
name: spec-scan
description: Trigger a full codebase scan and update the project profile
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Task
  - AskUserQuestion
---

# /spec-scan Command

Explicitly trigger a full codebase scan to create or update the project profile (`_project-profile.md`). This profile tells other spec agents how the project is wired -- where routes are registered, how navigation works, what entities exist, and what patterns the codebase follows.

## Workflow

### Step 1: Preserve Existing Sections

Check for an existing project profile:

1. Look for `.claude/specs/_project-profile.md` or `.claude/specs/_profile-index.md`.
2. If found, read the file and extract these sections verbatim (including all content under them):
   - `## Manual Overrides`
   - `## Regression Markers`
3. Store the extracted content for merging later. These sections are **user-curated** and must survive rescans unchanged.

If no existing profile is found, skip this step.

### Step 2: Invoke the Spec Scanner Agent

Use the Task tool to invoke the `spec-scanner` agent:

- Pass the project root directory as the working directory.
- The agent will scan the codebase and produce a fresh `_project-profile.md` (or domain-split files with `_profile-index.md` for large projects).
- Wait for the agent to complete.

### Step 3: Merge Preserved Sections

After the scanner finishes:

1. Read the newly generated profile.
2. If Manual Overrides content was preserved from Step 1:
   - Replace the scanner's default `## Manual Overrides` section with the preserved content.
3. If Regression Markers content was preserved from Step 1:
   - Replace the scanner's default `## Regression Markers` section with the preserved content.
4. Write the merged profile back to disk.

**Rule**: `## Manual Overrides` and `## Regression Markers` are preserved verbatim across rescans. The scanner never overwrites user-curated content in these sections.

### Step 4: Handle Split Profiles

If the scanner produced domain-split files (`_profile-<domain>.md` + `_profile-index.md`):

1. The Manual Overrides and Regression Markers sections live in the main `_profile-index.md` file, not in individual domain files.
2. Merge the preserved sections into `_profile-index.md`.

### Step 5: Print Summary

After the profile is written, print a summary report:

```
## Scan Complete

| Metric                  | Count |
|-------------------------|-------|
| Patterns detected       | X     |
| High confidence         | X     |
| Medium confidence       | X     |
| Low confidence          | X     |
| Entities found          | X     |
| Registration points     | X     |

Profile written to: `.claude/specs/_project-profile.md`
```

To calculate the summary:
- **Patterns detected**: Count entries under `## Patterns`.
- **Confidence breakdown**: Count `[confidence: high]`, `[confidence: medium]`, `[confidence: low]` labels.
- **Entities found**: Count rows in the `## Entity Registry` table (excluding the header row).
- **Registration points**: Count bullet items under `## Registration Points`.

## When to Use

- **First time**: Run `/spec-scan` before your first `/spec` to give all agents project context.
- **After major refactors**: Rescan to pick up structural changes (new frameworks, renamed directories, new registration patterns).
- **Manual trigger**: The `/spec` command auto-scans if no profile exists, but `/spec-scan` lets you force a rescan at any time.

## Notes

- The scanner respects security rules: `.env` files, credentials, keys, and sensitive directories are never read.
- For monorepos with 2+ manifest files in distinct subdirectories, the scanner produces per-app profiles.
- If no framework is detected, the scanner writes a minimal `confidence: low` profile and suggests adding details to Manual Overrides.

## Example Usage

```
/spec-scan
```
