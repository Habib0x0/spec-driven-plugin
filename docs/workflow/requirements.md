# Requirements

The requirements phase captures what the system must do. Every requirement is written in EARS notation so it is unambiguous and testable.

## Starting requirements

Run `/spec <feature-name>` to start. The spec-planner (opus tier) will:

1. Ask clarifying questions about feature scope
2. Identify user roles and their goals
3. Write user stories with EARS acceptance criteria
4. Identify non-functional requirements (performance, security, accessibility)
5. Document out-of-scope items explicitly
6. List open questions for resolution

If you have a feature brief from `/spec-brainstorm`, provide it as context.

## User story format

```markdown
### US-1: [Story Title]

**As a** [user role]
**I want** [goal or desire]
**So that** [benefit or value]

#### Acceptance Criteria (EARS)

1. WHEN [condition]
   THE SYSTEM SHALL [behavior]
```

## EARS notation

All acceptance criteria use EARS (Easy Approach to Requirements Syntax).

### Event-driven: WHEN

For behavior triggered by a specific event:

```
WHEN a user submits a login form with valid credentials
THE SYSTEM SHALL authenticate the user and create a session

WHEN a user fails authentication 5 times within 15 minutes
THE SYSTEM SHALL temporarily lock the account for 30 minutes
```

### State-driven: WHILE

For behavior that applies as long as a state holds:

```
WHILE the user is logged in
THE SYSTEM SHALL display the user's profile in the navigation bar

WHILE data is being fetched from the API
THE SYSTEM SHALL display a loading indicator
```

### Conditional: IF / WHEN

For behavior with a prerequisite condition:

```
IF the user has admin privileges
WHEN they access the settings page
THE SYSTEM SHALL display advanced configuration options

IF the cart total exceeds $100
WHEN the user proceeds to checkout
THE SYSTEM SHALL apply free shipping
```

### Ubiquitous (no keyword)

For behavior that always applies regardless of state or event:

```
THE SYSTEM SHALL encrypt all data at rest using AES-256
THE SYSTEM SHALL log all authentication attempts
```

### Negative: SHALL NOT

For behavior that must never occur:

```
THE SYSTEM SHALL NOT store passwords in plain text
THE SYSTEM SHALL NOT allow more than 5 failed login attempts per hour
```

### Optional: MAY

For behavior that is desirable but not required:

```
THE SYSTEM MAY suggest related products based on browsing history
THE SYSTEM MAY cache API responses for improved performance
```

## Writing good requirements

**Be specific.** Avoid vague language.

Bad: `THE SYSTEM SHALL handle errors gracefully`

Good: `WHEN an API request fails with a 5xx error, THE SYSTEM SHALL display "Service temporarily unavailable" and log the error`

**Include measurable criteria** for performance and reliability.

Bad: `THE SYSTEM SHALL respond quickly`

Good: `THE SYSTEM SHALL respond to API requests within 200ms for the 95th percentile`

**One behavior per requirement.** If a requirement contains "and," split it.

**Cover edge cases:** empty states, error conditions, boundary values, concurrent operations, offline states.

## Validation

The spec-validator checks requirements for:

- Proper EARS notation (no vague terms like "quickly," "properly," "easily")
- Completeness — each user story has at least one acceptance criterion
- Consistency — no conflicting requirements
- Traceability — requirements are referenced in tasks

Run `/spec-validate` to check at any time.

## Refinement

Use `/spec-refine` to update requirements after the initial spec is created. Updated requirements will prompt a review of the design to ensure alignment.

## Starting from an existing document

If you have an existing PRD or design document, paste its contents into `/spec <name>` as context and instruct the spec-planner to derive EARS requirements from it. Review the output, then proceed to design.
