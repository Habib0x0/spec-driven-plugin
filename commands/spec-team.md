---
name: spec-team
description: Execute spec with a coordinated agent team (Implementer, Tester, Reviewer, Debugger)
allowed-tools:
  - Bash
  - Read
  - Glob
---

# /spec-team Command

Run spec implementation with a full agent team. The Lead coordinates 4 specialized teammates:

| Agent | Model | Role |
|-------|-------|------|
| Implementer | Sonnet | Writes code for tasks |
| Tester | Sonnet | Verifies with Playwright/tests |
| Reviewer | Opus | Code quality, security, architecture |
| Debugger | Sonnet | Fixes issues when rejected |

## Usage

Run the script directly from your project root:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/spec-team.sh [--spec-name <name>] [--max-iterations <n>]
```

## How It Works

For each task:

```
1. Implementer writes code
         ↓
2. Tester verifies (Playwright/tests)
         ↓ PASS          ↓ FAIL
3. Reviewer checks      Debugger fixes
         ↓ APPROVE       ↓ REJECT
4. Commit             Back to step 2/3
```

## When to Use

Use `/spec-team` instead of `/spec-loop` when:
- Tasks were being marked complete without real testing
- You need security/quality review before commits
- The feature is complex or security-sensitive
- You want separation of concerns (writer ≠ tester)

## Token Cost

Agent teams use ~3-4x more tokens than single-agent mode because each teammate has its own context. Use `/spec-loop` for simpler tasks.

## Prerequisites

- Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (set automatically by script)
- A completed spec in `.claude/specs/<name>/`
- Playwright MCP for UI testing
