---
name: spec-refine
description: Refine requirements or design for an existing spec
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - AskUserQuestion
---

# /spec-refine Command

Update requirements or design for an existing spec.

## Workflow

### 1. Identify Current Spec

Look for existing specs in `.claude/specs/`:

```bash
ls .claude/specs/
```

If multiple specs exist, ask which one to refine. If only one exists, use it automatically.

### 2. Read Current Spec

Read the current requirements.md and design.md:

```
.claude/specs/<feature-name>/requirements.md
.claude/specs/<feature-name>/design.md
```

### 3. Gather Refinements

Ask the user what needs to change:

1. New requirements to add?
2. Requirements to modify?
3. Requirements to remove?
4. Design changes needed?
5. New components or APIs?

### 4. Update Requirements (if changed)

If requirements changed:

1. Add new user stories with EARS acceptance criteria
2. Update existing stories as needed
3. Mark removed requirements as deprecated (don't delete history)
4. Update non-functional requirements
5. Update out-of-scope section

### 5. Update Design (if needed)

If requirements changed or design needs updates:

1. Review impacted components
2. Update architecture diagrams
3. Modify data models
4. Update API specifications
5. Revise sequence diagrams
6. Update security/performance considerations

### 6. Cascade to Tasks

After refining requirements or design:

1. Inform user that tasks may need updating
2. Suggest running `/spec-tasks` to regenerate tasks
3. Note which existing tasks might be affected

## Example Usage

```
/spec-refine
```

Then follow prompts to select spec and describe changes.

## Tips

- Keep change history - add notes about what changed and why
- After major requirement changes, always review the design
- After design changes, always review tasks
- Consider versioning specs for significant changes
