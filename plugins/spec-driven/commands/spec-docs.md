---
description: Generate user-facing documentation from spec and implementation
---

# /spec-docs

Generate documentation from spec files and implemented code. Produces API references, user guides, architecture decision records, and operations runbooks as appropriate.

## Philosophy

Specs are internal dev artifacts. Users, API consumers, and ops teams need different documentation. This command bridges that gap by generating targeted docs from the spec + actual implementation code.

## Workflow

### 1. Locate the Spec

If a spec name is provided, use it. Otherwise auto-detect from `.claude/specs/`.

### 2. Analyze What's Needed

Read the spec files and implementation to determine the feature type:

| Feature Type | Detected By | Docs Generated |
|-------------|-------------|----------------|
| API/Backend | API endpoints in design.md, server routes in code | API Reference, ADR |
| UI/Frontend | Components in design.md, UI files in code | User Guide, Component Ref |
| Full-Stack | Both API + UI elements | All docs |
| Library/SDK | Exported functions, package.json lib config | API Reference, Getting Started |
| Infrastructure | Deployment configs, CI/CD, env vars | Runbook, ADR |

Present the detected type and planned documents to the user via AskUserQuestion:
- **Generate all recommended docs** — Proceed with the detected set
- **Let me choose which docs** — Pick from the list
- **Custom output location** — Specify where docs should be written

Default output location: `.claude/specs/<feature-name>/docs/`

### 3. Spawn the Documenter Agent

Delegate to the **spec-driven:spec-documenter** agent via the Task tool.

Pass the agent:
- The spec directory path
- Which documents to generate
- The output directory
- Any user preferences about documentation style or audience

### 4. Present Results

When the documenter returns:

1. List all generated documents with brief descriptions
2. Highlight any discrepancies found between design.md and actual implementation
3. Note any documentation that couldn't be generated (and why)

Ask the user via AskUserQuestion:
- **Looks good** — Done
- **Move docs to project root** — Copy from spec dir to project `docs/` folder
- **Regenerate specific docs** — Re-run with adjustments
- **Edit manually** — User will refine the generated docs themselves

## Tips

- Run after `/spec-accept` for the most accurate documentation (you know what's actually shipped)
- The documenter uses actual code as source of truth, not just design.md
- Generated docs are a starting point — they capture structure and accuracy but may need voice/tone editing
- ADRs are especially valuable for future developers understanding why decisions were made
