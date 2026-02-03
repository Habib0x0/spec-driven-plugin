---
name: spec-validate
description: Validate spec completeness and consistency
allowed-tools:
  - Read
  - Glob
  - Grep
---

# /spec-validate Command

Validate that a spec is complete, consistent, and ready for implementation.

## Workflow

### 1. Identify Spec

Look for existing specs in `.claude/specs/`:

If multiple specs exist, ask which one to validate.

### 2. Check File Completeness

Verify all spec files exist:
- [ ] requirements.md exists
- [ ] design.md exists
- [ ] tasks.md exists

### 3. Validate Requirements

Check requirements.md for:

**Structure**
- [ ] Has overview section
- [ ] Has user stories section
- [ ] Each story has As a/I want/So that format
- [ ] Each story has acceptance criteria

**EARS Notation**
- [ ] All criteria use WHEN/THE SYSTEM SHALL format
- [ ] Criteria are specific and testable
- [ ] No vague terms ("quickly", "easily", "properly")

**Completeness**
- [ ] Non-functional requirements defined
- [ ] Out of scope section exists
- [ ] Open questions resolved (none marked with [ ])

### 4. Validate Design

Check design.md for:

**Structure**
- [ ] Has architecture overview
- [ ] Has component specifications
- [ ] Has data models defined

**Coverage**
- [ ] All requirements addressable by design
- [ ] Each component has clear purpose
- [ ] Interfaces defined between components

**Quality**
- [ ] Security considerations documented
- [ ] Performance considerations documented
- [ ] Alternatives considered with rationale

### 5. Validate Tasks

Check tasks.md for:

**Structure**
- [ ] Tasks organized by phase
- [ ] Each task has required fields (status, requirements, description, acceptance, dependencies)

**Traceability**
- [ ] All requirements have corresponding tasks
- [ ] No orphan tasks (tasks without requirement links)
- [ ] Dependencies form valid DAG (no cycles)

**Quality**
- [ ] Task descriptions are specific
- [ ] Acceptance criteria are testable
- [ ] Dependencies are reasonable

### 6. Cross-Reference Validation

Check consistency across files:

- [ ] Requirements IDs in tasks.md match requirements.md
- [ ] Components in tasks.md match design.md
- [ ] No contradictions between documents

### 7. Output Report

Generate validation report:

```
## Spec Validation: <feature-name>

### Summary
- Status: PASS / FAIL / WARNINGS
- Issues Found: X
- Warnings: Y

### Requirements Validation
✓ Structure complete
✓ EARS notation correct
⚠ 1 open question remaining

### Design Validation
✓ Architecture documented
✓ All requirements covered
✓ Security considerations present

### Tasks Validation
✓ All requirements have tasks
✓ Dependencies valid
✗ Task T-7 missing acceptance criteria

### Issues to Address

1. **[ERROR]** Task T-7 missing acceptance criteria
   - File: tasks.md
   - Fix: Add specific, testable acceptance criteria

2. **[WARNING]** Open question in requirements
   - File: requirements.md
   - Question: "Should we support OAuth?"
   - Action: Resolve before implementation

### Recommendations

- Address 1 error before starting implementation
- Consider resolving warning to avoid scope creep
```

## Validation Rules

### Requirements Rules
- R1: Each user story must have at least one acceptance criterion
- R2: All acceptance criteria must use EARS notation
- R3: No unresolved open questions

### Design Rules
- D1: Design must address all functional requirements
- D2: Each component must have defined interfaces
- D3: Security considerations must be documented

### Tasks Rules
- T1: Each requirement must map to at least one task
- T2: Each task must have testable acceptance criteria
- T3: Dependencies must not form cycles
- T4: All tasks must have valid status

## Example Usage

```
/spec-validate
```

## Tips

- Run before starting implementation
- Address all errors before proceeding
- Warnings are advisory but worth reviewing
- Re-validate after major spec changes
