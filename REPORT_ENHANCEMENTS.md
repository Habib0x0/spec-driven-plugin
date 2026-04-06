# Claude Code Report → Plugin Enhancements

## What Changed

This document summarizes improvements made to the spec-driven-plugin based on Claude Code usage analysis.

**Report Context:** 149 sessions, 1,525 messages (2026-02-20 to 2026-04-06)

**Key Findings:**
- 131 buggy-code incidents (missing validation, blind changes)
- 90 wrong-approach incidents (loops without stopping)
- 30-60 min sessions lost to API/rate-limit errors
- 45 "mostly achieved" outcomes (features incomplete/unverified)

**Solution:** Enhanced CLAUDE.md + improved slash command documentation.

---

## Changes Made

### 1. CLAUDE.md — 5 New Sections Added

📁 `spec-driven-plugin/CLAUDE.md`

#### Communication Style
- Don't analyze projects on simple greetings (hi, hello)
- Respond briefly, ask what user wants to work on

#### UI/TUI Development  
- Don't guess visual bugs from code alone
- Ask for visual descriptions; make minimal targeted changes

#### Config & Dotfiles
- Always verify changes took effect (reload + test)
- Never report success without verification

#### Languages & Build
- When editing Rust: run `cargo check` after changes
- When editing TypeScript: ensure `.tsx` for JSX, run `tsc --noEmit`
- When editing shell scripts: run `shellcheck`

#### Error Handling & Resilience
- Stop after 2 failed attempts; report what's blocking
- Run preflight checks before large workflows
- Use checkpoints for long runs; resume instead of restart
- Always reload and test config changes

**Impact:** Addresses 131 buggy-code + 90 wrong-approach incidents by encoding decision rules.

---

### 2. /spec-loop Command Enhanced

📁 `spec-driven-plugin/commands/spec-loop.md`

#### Added: Preflight Checklist
```bash
git remote -v        # Check git remote
claude -p "ok"       # Test model access
npm run build        # Verify build passing
[ -d .claude/specs ] # Confirm specs exist
grep TODO.md         # List blockers
```

Only proceed if all pass. 2-minute check saves hours.

#### Added: 3 Warning Signals
Watch for signals indicating when to **stop**:

1. **Repeated API Errors** (same error 3x) → Stop, diagnose root cause
2. **Task Fails Gate 2x** → Normal, acceptable; skip and continue
3. **Loop Exits Early** → Investigate before next run

#### Added: Error Recovery
1. Check progress.md and git log to understand what happened
2. Fix the blocker locally (build broken? rate limit? API down?)
3. Resume loop — checkpoint system skips completed tasks

#### Added: Running Effectively
- Small specs (5-10 tasks): 1 batch, 15 iterations
- Medium specs (15-25): multiple 10-15 iteration batches
- Large specs (40+): consider test-first or parallel teams

---

### 3. /spec-exec Command Enhanced

📁 `spec-driven-plugin/commands/spec-exec.md`

#### Added: Quick Preflight
- Check git remote
- Verify build clean
- Confirm spec exists

#### Added: Tips
- Run one task at a time
- Check progress.md after each iteration
- Use `/spec-loop` for batches
- Integration sweep only runs at end of full spec completion

---

### 4. Advanced Patterns Guide

📁 `spec-driven-plugin/ADVANCED_PATTERNS.md` — Reference material for power users

Four patterns from report's "On the Horizon":

1. **Test-Driven Autonomous Loops**
   - Enforce tests-first in spec execution
   - Fixes 40% completion rate bottleneck

2. **Parallel Agent Teams**
   - Structured task handoffs for independent work
   - Leverages your 67 multi-clauding overlap events

3. **Checkpoint Pipelines**
   - Phase-based execution that survives rate limits
   - Fixes 267-min API error spiral scenario

4. **Error Loop Prevention**
   - Explicit retry limits with diagnostic output
   - Prevents 37-60 min stuck loops

Includes: when to use each, implementation examples, preconditions.

---

### 5. Headless Orchestration Guide

📁 `spec-driven-plugin/HEADLESS_ORCHESTRATION.md` — Reference material

Alternative to tmux-based agent coordination:
- Direct CLI subprocess orchestration
- Parallel execution (all ready tasks simultaneously)
- Checkpoint recovery (resume after failures)
- CI/CD integration-ready

Use when: Large specs (20+ independent tasks), structured output needed.

---

## How These Address the Report

| Finding | Root Cause | Fix |
|---------|-----------|-----|
| **131 buggy-code** | Missing validation, blind changes | CLAUDE.md: Languages & Build (auto-checks after edits) |
| **90 wrong-approach** | Loops without stopping mechanism | CLAUDE.md: Error Handling (stop after 2 failures) |
| **30-60 min API errors** | No recovery mechanism | /spec-loop: Checkpoint recovery + warning signals |
| **45 mostly-achieved** | Missing verification | CLAUDE.md: Error Handling (mandatory preflight) |

---

## Plugin Installation & Usage

When plugin is installed, these improvements are immediately available:

### Slash Commands (from `commands/` directory)
```bash
/spec <name>              # Create new spec (unchanged)
/spec-loop               # Run batch loop (ENHANCED)
/spec-exec               # Run one iteration (ENHANCED)
/spec-validate           # Validate spec (unchanged)
/spec-docs              # Generate docs (unchanged)
# ... all other commands
```

### Project-Level Rules (from CLAUDE.md)
Automatically loaded when plugin is active in a project containing `.claude/` directory.

### Reference Docs
Available in repo for teams wanting to leverage:
- `ADVANCED_PATTERNS.md` — Power user workflows
- `HEADLESS_ORCHESTRATION.md` — Large-scale automation

---

## Quick Start for Users

When using this plugin:

### Before Running /spec-loop
1. Read the **Preflight Checklist** in `/spec-loop` docs
2. Understand the **3 Warning Signals** (when to pause)
3. Know **Error Recovery** steps if something fails

### Monitoring During Execution
- Watch progress.md every 5-10 iterations
- Stop if you see any warning signals
- Check git log + progress.md if loop fails

### Error Recovery
- Identify the blocker (API down? Build broken? Rate limit?)
- Fix it locally
- Resume — checkpoint system handles the rest

---

## Files Modified

✅ **CLAUDE.md** — Added 5 sections (Error Handling, Languages & Build, etc.)

✅ **commands/spec-loop.md** — Added preflight, monitoring, recovery guidance

✅ **commands/spec-exec.md** — Added quick preflight and tips

### Files Added (Reference Material)

✅ **ADVANCED_PATTERNS.md** — 4 power user patterns with examples

✅ **HEADLESS_ORCHESTRATION.md** — Alternative orchestration approach

---

## Files Unchanged

✅ **scripts/spec-loop.sh** — Already excellent; no changes needed

✅ **scripts/spec-exec.sh** — Solid implementation

✅ **.claude/settings.local.json** — Permissions appropriate

---

## Measurement

Track these to validate improvements:

| Metric | Before | Target |
|--------|--------|--------|
| Spec-loop completion rate | ~40% | >80% |
| Buggy code per session | 2.5 avg | <0.5 avg |
| "Mostly achieved" outcomes | 45 | <10 |
| Session duration (40-task) | 3-4 hrs | 2-3 hrs |
| Recovery time after rate limit | Session lost | <5 min |

---

## For Users of This Plugin

1. **Read** `/spec-loop` command docs before running loops
2. **Follow** the preflight checklist
3. **Watch** for the 3 warning signals during execution
4. **Reference** ADVANCED_PATTERNS.md for complex specs
5. **Use** HEADLESS_ORCHESTRATION.md for parallel work

All improvements are baked into the plugin—no separate configuration needed.
