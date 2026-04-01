---
name: spec-debug
description: Diagnose and fix bugs within the spec context with regression tracking
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Task
  - AskUserQuestion
---

# /spec-debug Command

Standalone bug-fixing workflow with spec context awareness and regression tracking. Invokes the `spec-debugger` agent to investigate, diagnose, and fix bugs, then records a regression marker in the project profile to prevent recurrence.

## Workflow

### Step 1: Collect Bug Description

Use AskUserQuestion to gather the bug details from the user:

1. **Symptom**: What the user observed (error message, unexpected behavior, crash).
2. **Error message or stack trace**: If available, the full error output.
3. **Affected area**: Which part of the application is affected (e.g., "invoice API", "login page", "sidebar navigation").

Combine these into a structured bug context string for the debugger agent.

### Step 2: Invoke the Spec-Debugger Agent

Use the Task tool to invoke the `spec-debugger` agent:

- **Agent**: `spec-debugger`
- **Prompt**: Pass the full bug context collected in Step 1 (symptom, error/stack trace, affected area).
- **Mode**: The agent runs in "Standalone Debug Mode" -- it will investigate, diagnose, apply a fix, and write `diagnosis.md` and `fix.md`.
- Wait for the agent to complete. The agent will output the directory path where it wrote its files.

### Step 3: Read Debugger Output

After the debugger returns:

1. Read `diagnosis.md` from the directory the agent wrote to (the matched spec directory or `debug-<slug>/`).
2. Read `fix.md` from the same directory.
3. Extract key fields: Bug ID, Root Cause, Files Modified, Regression Check description, Attempts count, Retro status.

### Step 4: Verify Regression Marker

Check whether the debugger appended a regression marker to the project profile:

1. Read `.claude/specs/_project-profile.md` (or `_profile-index.md` for split profiles).
2. Look for a `### BUG-XXX` entry under `## Regression Markers` matching the Bug ID from `fix.md`.
3. If the marker is present, proceed to Step 5.
4. If the marker is missing, add it manually using this format:

```markdown
### BUG-XXX: [Short title] (YYYY-MM-DD)

- **Files**: `file1.ts`, `file2.ts`
- **Check**: [Regression check description from fix.md]
```

Append this under the `## Regression Markers` section. If no profile exists, skip this step and log: "No project profile -- regression marker not recorded."

### Step 5: Evaluate Retro Trigger

Check the `fix.md` output for retro trigger conditions:

- **Auto-trigger `/spec-retro`** if ANY of these are true:
  - The fix touched **3 or more files** (count entries under `Files Modified` in `fix.md`)
  - The fix required **multiple attempts** (`Attempts` > 1 in `fix.md`)
  - The debugger signaled `RETRO_RECOMMENDED` in its output

- If retro is auto-triggered: invoke `/spec-retro` passing the relevant spec name (or the `debug-<slug>` name).
- If retro is NOT auto-triggered: append a note to `progress.md` suggesting the user run `/spec-retro` manually:
  ```
  > Tip: Run `/spec-retro` to capture lessons from BUG-XXX if needed.
  ```

### Step 6: Print Summary

Print a final summary with these fields:

```
## Debug Summary

| Field              | Value                                       |
|--------------------|---------------------------------------------|
| Bug ID             | BUG-XXX                                     |
| Root Cause         | [1-2 sentence summary from diagnosis.md]    |
| Files Modified     | file1.ts, file2.ts                          |
| Regression Check   | [description from fix.md]                   |
| Retro              | auto-triggered / suggested / not needed     |
```

## Spec-Matching Algorithm

The debugger uses a file-overlap algorithm to find the most relevant spec context:

1. The debugger identifies affected files during investigation (e.g., `src/api/invoices.ts`, `src/components/InvoiceForm.tsx`).
2. For each `.claude/specs/*/tasks.md`, count how many task descriptions or file references overlap with the affected files.
3. The spec with the highest overlap count is the match -- the debugger writes `diagnosis.md` and `fix.md` into that spec's directory.
4. If overlap count is 0 for all specs, or if no specs exist, create a standalone `debug-<slug>/` directory under `.claude/specs/`.
5. If two specs tie, pick the one modified more recently.

**`debug-<slug>/` naming**: The slug is derived from the first 3-4 words of the bug description in kebab-case (e.g., "Invoice total not calculating" becomes `debug-invoice-total-not/`).

## Edge Cases

- **No `.claude/specs/` directory**: The debugger creates it along with `debug-<slug>/`.
- **No project profile**: Regression marker step is skipped with a log message. The debugger still operates normally.
- **Debugger fails to fix**: `fix.md` will have `Attempts` reflecting the failure. The command still prints the summary with the diagnosis for manual follow-up.

## Example Usage

```
/spec-debug
```

The command will prompt you for the bug details interactively.
