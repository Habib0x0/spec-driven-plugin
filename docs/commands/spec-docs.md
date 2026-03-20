# /spec-docs

Generate user-facing documentation from the spec and implemented code. Produces API references, user guides, architecture decision records (ADRs), and operations runbooks depending on the type of feature built.

## Usage

```
/spec-docs [spec-name]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `spec-name` | No | Name of the spec to document. Auto-detected if only one spec exists. |

## What It Does

1. **Locates the spec** and reads spec files alongside the actual implementation code.

2. **Detects the feature type** and determines which documents are appropriate:

   | Feature Type | Documents Generated |
   |---|---|
   | API / Backend | API Reference, ADR |
   | UI / Frontend | User Guide, Component Reference |
   | Full-Stack | All of the above |
   | Library / SDK | API Reference, Getting Started guide |
   | Infrastructure | Runbook, ADR |

3. **Asks for confirmation** — shows the detected type and planned documents, then lets you approve, choose specific docs, or specify a custom output location.

4. **Generates documentation** — reads the actual implementation as the source of truth (not just `design.md`), so the output reflects what was actually built. Default output location: `.claude/specs/<feature-name>/docs/`.

5. **Reports results** — lists all generated documents with brief descriptions and highlights any discrepancies between `design.md` and the actual implementation found during generation.

6. **Offers next steps** — move docs to the project's `docs/` folder, regenerate specific documents, or mark them for manual editing.

## Example

```
/spec-docs payment-flow
```

## Tips

- Run this after `/spec-accept` for the most accurate documentation — you know exactly what shipped.
- The generated docs are a strong starting point for accuracy and structure, but may need tone and voice editing before publishing.
- ADRs are especially valuable for future developers who need to understand why decisions were made — do not skip them for complex features.
- If the implementation diverged from `design.md`, the discrepancies report tells you exactly where.

!!!note
    Documentation is generated from actual code, not just the spec. If the implementation is incomplete or differs from the design, those differences will appear in the output.

## See Also

- [/spec-accept](spec-accept.md) — Complete acceptance testing before generating docs
- [/spec-release](spec-release.md) — Generate release notes alongside documentation
- [/spec-retro](spec-retro.md) — Capture lessons learned after the feature ships
