# /spec-import

Convert an existing markdown document — a PRD, RFC, or design doc — into a spec with properly structured requirements in EARS notation. Use this when you already have written documentation and want to bring it into the spec-driven workflow without starting from scratch.

## Usage

```
/spec-import <feature-name> --file <path>
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `feature-name` | Yes | Name for the new spec. Kebab-case recommended. |
| `--file <path>` | Yes | Path to the source markdown document to import. |

## What It Does

1. **Validates the source file** — confirms the file exists and is readable before creating anything. If the file is not found, the command stops without creating any spec directory.

2. **Creates the spec directory** at `.claude/specs/<feature-name>/`. If a spec already exists at that path, asks whether to overwrite or cancel.

3. **Converts to structured requirements** — reads the source document and extracts all requirements, feature descriptions, goals, and constraints. Organizes them into user stories with EARS acceptance criteria (`WHEN ... THE SYSTEM SHALL ...` format). Identifies user roles, non-functional requirements, and out-of-scope items from the source text.

4. **Writes `requirements.md` only** — the import produces requirements. Design and tasks are intentionally left for subsequent steps so you can review and refine before proceeding.

5. **Reports completion** — summarizes the import and recommends next steps.

!!!warning
    If the source document has limited requirements content — very short, or lacking clear features and goals — the command will warn you that manual review is strongly recommended.

## Example

```
/spec-import user-auth --file docs/auth-prd.md
/spec-import payment-flow --file ~/Documents/payment-rfc.md
```

## Tips

- After importing, review `requirements.md` to verify the conversion captured intent correctly. Source documents often have implicit requirements that need to be made explicit.
- Run `/spec-refine` to adjust any requirements before moving forward.
- Once requirements look right, run `/spec` (or proceed manually) to generate the design and tasks.
- The import does not ask clarifying questions — it works with what the document provides. If the source is ambiguous, you will need to refine the output.

## See Also

- [/spec](spec.md) — Start a spec interactively from scratch
- [/spec-brainstorm](spec-brainstorm.md) — Explore an idea before committing to a spec
- [/spec-refine](spec-refine.md) — Adjust requirements after import
- [/spec-tasks](spec-tasks.md) — Generate tasks once requirements and design are ready
