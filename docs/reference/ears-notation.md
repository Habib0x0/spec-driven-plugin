# EARS Notation

EARS (Easy Approach to Requirements Syntax) is a structured format for writing clear, unambiguous acceptance criteria. This reference covers every pattern variant with examples, writing guidelines, and a checklist for verifying requirement quality.

Use this page when writing or reviewing the `requirements.md` file in your spec. Every acceptance criterion in that file should follow one of the patterns described here.

---

## Core Pattern

The fundamental EARS pattern expresses a trigger and the expected system behavior:

```
WHEN [precondition/trigger]
THE SYSTEM SHALL [expected behavior]
```

The keyword `SHALL` means the behavior is mandatory. There is no ambiguity — the system either satisfies it or it does not.

---

## Pattern Variants

### Ubiquitous Requirements

For behavior that must always hold, regardless of any trigger:

```
THE SYSTEM SHALL [behavior]
```

**Examples:**

```
THE SYSTEM SHALL encrypt all data at rest using AES-256
THE SYSTEM SHALL log all authentication attempts
```

Use this pattern for security rules, compliance requirements, and invariants that apply everywhere in the system.

---

### Event-Driven Requirements

For behavior triggered by a specific user action or system event:

```
WHEN [event occurs]
THE SYSTEM SHALL [response]
```

**Examples:**

```
WHEN a user clicks the submit button
THE SYSTEM SHALL validate all form fields before submission

WHEN a payment is processed successfully
THE SYSTEM SHALL send a confirmation email to the user
```

This is the most common pattern. Most user-facing features are naturally event-driven.

---

### State-Driven Requirements

For behavior that applies continuously while the system is in a particular state:

```
WHILE [state condition]
THE SYSTEM SHALL [behavior]
```

**Examples:**

```
WHILE the user is logged in
THE SYSTEM SHALL display the user's profile in the navigation bar

WHILE the system is in maintenance mode
THE SYSTEM SHALL display a maintenance notification banner
```

Use `WHILE` instead of `WHEN` when the condition is ongoing rather than a point-in-time event.

---

### Conditional Requirements

For behavior that depends on both a precondition and a trigger:

```
IF [condition]
WHEN [trigger]
THE SYSTEM SHALL [behavior]
```

**Examples:**

```
IF the user has admin privileges
WHEN they access the settings page
THE SYSTEM SHALL display advanced configuration options

IF the cart total exceeds $100
WHEN the user proceeds to checkout
THE SYSTEM SHALL apply free shipping
```

The `IF` clause narrows the population to which the requirement applies. The `WHEN` clause specifies the triggering event within that population.

---

### Negative Requirements

For behaviors that must never occur:

```
THE SYSTEM SHALL NOT [prohibited behavior]
```

**Examples:**

```
THE SYSTEM SHALL NOT store passwords in plain text
THE SYSTEM SHALL NOT allow more than 5 failed login attempts per hour
```

Negative requirements are especially useful for security constraints and data protection rules.

---

### Optional Features

For behaviors that may be implemented but are not mandatory:

```
THE SYSTEM MAY [optional behavior]
```

**Examples:**

```
THE SYSTEM MAY suggest related products based on browsing history
THE SYSTEM MAY cache API responses for improved performance
```

`MAY` signals a nice-to-have. Use it sparingly — if a behavior truly matters, it should be `SHALL`.

---

## Complete Examples by Domain

The following examples show how multiple EARS requirements work together to fully specify a feature.

### Authentication

```
US-1: User Login

WHEN a user submits valid credentials
THE SYSTEM SHALL authenticate the user and create a session

WHEN a user submits invalid credentials
THE SYSTEM SHALL display an error message without revealing which field is incorrect

WHEN a user fails authentication 5 times within 15 minutes
THE SYSTEM SHALL temporarily lock the account for 30 minutes

WHEN a user requests password reset
THE SYSTEM SHALL send a reset link valid for 1 hour

THE SYSTEM SHALL NOT store passwords in plain text
THE SYSTEM SHALL hash passwords using bcrypt with cost factor 12
```

### Form Validation

```
US-2: Form Validation

WHEN a user submits a form with missing required fields
THE SYSTEM SHALL highlight the missing fields and display inline error messages

WHEN a user enters an invalid email format
THE SYSTEM SHALL display "Please enter a valid email address"

WHEN a user enters a password shorter than 8 characters
THE SYSTEM SHALL display password strength requirements

WHILE the user is typing in a field with validation errors
THE SYSTEM SHALL clear the error when the input becomes valid
```

### API Error Handling

```
US-3: API Error Handling

WHEN an API request times out after 30 seconds
THE SYSTEM SHALL retry the request up to 3 times with exponential backoff

WHEN an API returns a 4xx error
THE SYSTEM SHALL display a user-friendly error message

WHEN an API returns a 5xx error
THE SYSTEM SHALL display "Service temporarily unavailable" and log the error

IF the user is offline
WHEN they attempt an API request
THE SYSTEM SHALL queue the request and retry when connectivity is restored
```

### Data Management

```
US-4: Data CRUD Operations

WHEN a user creates a new record
THE SYSTEM SHALL validate all required fields before saving

WHEN a user updates a record
THE SYSTEM SHALL maintain an audit trail of changes

WHEN a user deletes a record
THE SYSTEM SHALL soft-delete by setting a deleted_at timestamp

WHEN a user requests deleted records
THE SYSTEM SHALL NOT include soft-deleted records unless explicitly requested
```

### Real-Time Features

```
US-5: Live Updates

WHILE a user is viewing a dashboard
THE SYSTEM SHALL refresh data every 30 seconds

WHEN new data is available
THE SYSTEM SHALL display a notification without refreshing the page

WHEN the WebSocket connection is lost
THE SYSTEM SHALL attempt to reconnect with exponential backoff

WHEN reconnection fails after 5 attempts
THE SYSTEM SHALL fall back to polling every 60 seconds
```

---

## Writing Good Requirements

### Be Specific

Vague language leaves requirements untestable.

!!! failure "Vague"
    ```
    WHEN the user makes an error
    THE SYSTEM SHALL handle it gracefully
    ```

!!! success "Specific"
    ```
    WHEN the user submits a form with invalid data
    THE SYSTEM SHALL display inline validation errors next to each invalid field
    ```

---

### Include Measurable Criteria

Performance and reliability requirements must be quantified.

!!! failure "Unmeasurable"
    ```
    THE SYSTEM SHALL respond quickly
    ```

!!! success "Measurable"
    ```
    THE SYSTEM SHALL respond to API requests within 200ms for the 95th percentile
    ```

---

### Cover Edge Cases

When writing requirements for a feature, explicitly consider:

- Empty states (no data, no results)
- Error conditions (network failure, invalid input, timeouts)
- Boundary values (maximum lengths, zero quantities, expiry thresholds)
- Concurrent operations (two users editing the same record)
- Degraded states (offline mode, partial outages, slow connections)

Each of these deserves its own `WHEN` or `WHILE` requirement if the behavior matters.

---

### One Behavior Per Requirement

Bundling multiple behaviors into a single requirement makes it hard to test and hard to track.

!!! failure "Bundled (avoid)"
    ```
    WHEN a user logs in
    THE SYSTEM SHALL authenticate them, create a session, log the event, and redirect to dashboard
    ```

!!! success "Separated (preferred)"
    ```
    WHEN a user submits valid credentials
    THE SYSTEM SHALL authenticate the user

    WHEN authentication succeeds
    THE SYSTEM SHALL create a session with 24-hour expiry

    WHEN a session is created
    THE SYSTEM SHALL log the authentication event

    WHEN authentication completes successfully
    THE SYSTEM SHALL redirect to the dashboard
    ```

Separating behaviors makes each requirement independently testable and traceable to specific implementation tasks.

---

## Acceptance Criteria Checklist

Before finalizing requirements, verify each EARS statement against this checklist:

| Property | Question to ask |
|----------|----------------|
| **Clear** | Is the language unambiguous? Could two engineers interpret it differently? |
| **Testable** | Can a test be written that definitively passes or fails? |
| **Complete** | Does it specify all relevant conditions? |
| **Consistent** | Does it conflict with any other requirement? |
| **Traceable** | Does it link back to a user story? |
| **Feasible** | Is it technically achievable within the project constraints? |

A requirement that fails any of these checks should be rewritten before moving to the design phase.
