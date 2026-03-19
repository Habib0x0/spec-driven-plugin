---
name: spec-import
description: Import a markdown document (PRD, RFC, design doc) and convert it to spec requirements
argument-hint: "<feature-name> --file <path>"
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Task
  - AskUserQuestion
---

# /spec-import Command

Import an existing markdown document (PRD, RFC, design doc) and convert it into a spec with EARS notation requirements.

## Arguments

- `feature-name` (required): Name for the feature spec (kebab-case recommended)
- `--file <path>` (required): Path to the source markdown document

## Workflow

### 1. Parse Arguments

Extract `<feature-name>` and `--file <path>` from the command arguments.

If `--file` is missing or no path is provided, print the following usage message and stop:

```
Usage: /spec-import <feature-name> --file <path>

Example: /spec-import user-auth --file docs/auth-prd.md
```

### 2. Validate Source File

Check that the file at `<path>` exists and is readable using the Read tool.

- If the file does not exist, print "Error: File not found: <path>" and stop. Do NOT create any spec directory.
- If the file extension is not `.md` or `.markdown`, print "Warning: File may not be markdown. Proceeding with import." and continue.

### 3. Read Source Content

Read the full content of the source file using the Read tool.

### 4. Create Spec Directory

Create the spec directory at `.claude/specs/<feature-name>/`. If the directory already exists, ask the user via AskUserQuestion whether to overwrite the existing requirements.md or cancel.

### 5. Delegate to spec-planner Agent

Use the Task tool to delegate to the **spec-planner** agent (Opus). Pass it all of the following:

- The feature name
- The spec directory path: `.claude/specs/<feature-name>/`
- The full content of the source document
- These instructions:

> Convert this document into a well-structured requirements.md following the spec-driven plugin format. Do the following:
>
> 1. Extract all requirements, feature descriptions, goals, and constraints from the document
> 2. Identify user roles mentioned or implied in the document
> 3. Organize requirements into User Stories with the format: "As a <role>, I want <goal>, So that <benefit>"
> 4. Write EARS acceptance criteria for each user story using WHEN/THE SYSTEM SHALL notation
> 5. Extract any non-functional requirements (performance, security, reliability)
> 6. Identify anything explicitly marked as out of scope
> 7. Include a `## Depends On` section (empty if no dependencies are mentioned)
> 8. Write the output to `.claude/specs/<feature-name>/requirements.md`
>
> Do NOT generate design.md or tasks.md. Only generate requirements.md.
> Do NOT ask any clarifying questions. Work with what the document provides.

### 6. Post-Import Summary

After the spec-planner agent completes:

- If the source document had limited requirements content (very short, no clear features or goals), print: "Warning: Source document had limited requirements content. Manual review is strongly recommended."
- Print: "Import complete. Review requirements at .claude/specs/<feature-name>/requirements.md"
- Print: "Run /spec-refine to adjust requirements, then proceed to design."

## Example Usage

```
/spec-import user-auth --file docs/auth-prd.md
/spec-import payment-flow --file ~/Documents/payment-rfc.md
/spec-import dashboard --file specs/dashboard-design.markdown
```
