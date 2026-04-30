# /ubiquitous-language

Extract and formalize domain terminology from the codebase and conversation into a canonical glossary, flagging ambiguities and inconsistencies. Saves to `UBIQUITOUS_LANGUAGE.md`.

## Usage

```
/ubiquitous-language [domain area]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `domain area` | No | Optional focus — e.g., "billing", "auth", "user model". Scans the whole codebase if omitted. |

## What It Does

1. **Scans** the codebase and current conversation for domain-relevant nouns, verbs, and concepts.

2. **Identifies problems:**
   - Same word used for different concepts (ambiguity)
   - Different words used for the same concept (synonyms)
   - Vague or overloaded terms

3. **Proposes a canonical glossary** with opinionated term choices — one precise word per concept.

4. **Writes `UBIQUITOUS_LANGUAGE.md`** to the working directory.

5. **Outputs a summary** inline in the conversation highlighting the most important decisions and flagged ambiguities.

## Output File Format

```markdown
# Ubiquitous Language

## Canonical Terms

| Term | Definition | Avoid |
|------|-----------|-------|
| User | A registered human with login credentials | Account, Member, Person |
| Session | An authenticated browser session with an expiry | Auth, Token (when referring to the session itself) |

## Flagged Ambiguities

- **"Account"** — used to mean both User (in auth/) and BillingAccount (in billing/). Recommend: User and BillingAccount.
- **"Token"** — overloaded: JWT token, API token, reset token. Recommend explicit names.
```

## When to Use

- Before writing a spec for a complex domain to ensure requirements use consistent terms
- When onboarding to an unfamiliar codebase
- When a team is using inconsistent terminology and it's causing confusion in code and specs

## Example

```
/ubiquitous-language billing
```

## See Also

- [/spec](spec.md) — Use the glossary as context when writing requirements
- [/research](research.md) — Deep research before planning
