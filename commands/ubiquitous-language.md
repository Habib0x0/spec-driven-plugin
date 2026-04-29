---
name: ubiquitous-language
description: "Extract and formalize domain terminology into a canonical glossary, flagging ambiguities and proposing precise terms. Saves to UBIQUITOUS_LANGUAGE.md."
argument-hint: "[domain area]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
---

$ARGUMENTS

Extract and formalize domain terminology from the current conversation into a consistent glossary, saved to a local file.

## Process

1. **Scan the conversation** for domain-relevant nouns, verbs, and concepts
2. **Identify problems**:
   - Same word used for different concepts (ambiguity)
   - Different words used for the same concept (synonyms)
   - Vague or overloaded terms
3. **Propose a canonical glossary** with opinionated term choices
4. **Write to `UBIQUITOUS_LANGUAGE.md`** in the working directory using the format below
5. **Output a summary** inline in the conversation

## Output Format

Write a `UBIQUITOUS_LANGUAGE.md` file with this structure:

```md
# Ubiquitous Language

## [Group 1]

| Term | Definition | Aliases to avoid |
| ---- | ---------- | ---------------- |
| **Term** | One-sentence definition | Other names to avoid |

## [Group 2]

| Term | Definition | Aliases to avoid |
| ---- | ---------- | ---------------- |
| **Term** | One-sentence definition | Other names to avoid |

## Relationships

- A **Thing** belongs to exactly one **Other Thing**
- An **X** produces one or more **Y**

## Example dialogue

> **Dev:** "..."
> **Domain expert:** "..."
> **Dev:** "..."
> **Domain expert:** "..."

## Flagged ambiguities

- "word" was used to mean both **Concept A** and **Concept B** — these are distinct because...
```

## Rules

- **Be opinionated.** When multiple words exist for the same concept, pick the best one and list the others as aliases to avoid.
- **Flag conflicts explicitly.** If a term is used ambiguously in the conversation, call it out in the "Flagged ambiguities" section with a clear recommendation.
- **Only include terms relevant for domain experts.** Skip module or class names unless they have domain meaning.
- **Keep definitions tight.** One sentence max. Define what it IS, not what it does.
- **Show relationships.** Use bold term names and express cardinality where obvious.
- **Only include domain terms.** Skip generic programming concepts (array, function, endpoint) unless they have domain-specific meaning.
- **Group terms into multiple tables** when natural clusters emerge (e.g. by subdomain, lifecycle, or actor). Each group gets its own heading and table.
- **Write an example dialogue.** A short conversation (3-5 exchanges) between a dev and a domain expert that demonstrates how the terms interact naturally.

## Re-running

When invoked again in the same conversation:

1. Read the existing `UBIQUITOUS_LANGUAGE.md`
2. Incorporate any new terms from subsequent discussion
3. Update definitions if understanding has evolved
4. Re-flag any new ambiguities
5. Rewrite the example dialogue to incorporate new terms
