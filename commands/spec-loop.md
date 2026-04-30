---
name: spec-loop
description: Loop spec execution until all tasks are complete
allowed-tools:
  - Bash
  - Read
  - Glob
---

# /spec-loop Command

Run spec-driven implementation in a loop. Each iteration picks the next highest-priority task, implements it, and continues until all tasks are done or max iterations reached.

## Usage

Run the script directly from your project root:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/spec-loop.sh [--spec-name <name>] [--max-iterations <n>] [--progress-tail <n>] [--on-complete <command>]
```

Or via Bash tool if invoked within Claude Code:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/spec-loop.sh --spec-name <name>
```

## Arguments

- `--spec-name <name>` - Which spec to execute against. Auto-detected if only one spec exists in `.claude/specs/`.
- `--max-iterations <n>` - Maximum number of iterations before stopping. Default: 50.
- `--progress-tail <n>` - Number of recent progress entries to include in prompt. Default: 20.
- `--on-complete <command>` - Shell command to run after clean completion. Only fires when `<promise>COMPLETE</promise>` is detected, not on max-iterations exit. Recommended: `"bash scripts/spec-accept.sh --spec-name <name>"`.

## What It Does

1. Reads your spec files fresh each iteration
2. Runs Claude to implement one feature per iteration
3. Runs verification gates on completed tasks
4. Checks output for `<promise>COMPLETE</promise>` to detect completion
5. Stops when all tasks are done or max iterations reached

**Recommended hook** — run UAT automatically on clean completion:
```bash
bash scripts/spec-loop.sh --spec-name <name> \
  --on-complete "bash scripts/spec-accept.sh --spec-name <name>"
```

If you want docs too:
```bash
bash scripts/spec-loop.sh --spec-name <name> \
  --on-complete "bash scripts/spec-accept.sh --spec-name <name> && bash scripts/spec-docs.sh --spec-name <name>"
```

Post-completion (release notes, retro) should be run manually after reviewing acceptance results:
```bash
bash scripts/spec-accept.sh --spec-name <name>    # UAT gate
bash scripts/spec-docs.sh --spec-name <name>      # Docs
bash scripts/spec-release.sh --spec-name <name>   # Release notes
bash scripts/spec-retro.sh --spec-name <name>     # Retrospective
```

## Prerequisites

- A completed spec in `.claude/specs/<name>/` with all three files
- Run `/spec <name>` first if you haven't created a spec yet

## Preflight Checklist (IMPORTANT)

Before running `/spec-loop`, verify all green lights:

```bash
# 1. Git remote configured
git remote -v | head -1 && echo "✓ Git OK" || echo "✗ BLOCKED: No git remote"

# 2. Model access working
claude -p "ok" | head -1 && echo "✓ Model OK" || echo "✗ BLOCKED: Model unavailable"

# 3. Build passing
npm run build 2>&1 | grep -i error || echo "✓ Build OK"

# 4. Spec exists
[ -d ".claude/specs" ] && echo "✓ Specs found" || echo "✗ BLOCKED: No .claude/specs"

# 5. Any critical blockers?
echo "Known blockers (if any):"
[ -f "TODO.md" ] && grep -i "critical\|blocked\|broken" TODO.md || echo "  (none)"
```

**Only proceed if all checks pass.** A 2-minute preflight saves hours if the workflow fails mid-run.

## Monitoring During Execution

Watch for **3 warning signals** that indicate you should stop:

### Signal 1: Repeated API Errors
If the same error appears 3+ times unchanged, stop immediately. This is not transient.
```
Example: "API 400 Bad Request" in iterations 5, 6, 7
→ Action: Stop, diagnose the root cause, fix, resume
```

### Signal 2: Task Fails Verification Gate Twice
This is **normal and acceptable**. The loop will skip the task and continue.
```
Example: Task T-5 fails gate, retries debugger fix, still fails
→ Action: Continue to next task; you can investigate T-5 later
```

### Signal 3: Loop Exits Early Without Completing
If `--max-iterations` is reached before all tasks complete, investigate before next run.
```
Example: Run 15 iterations, only 5/20 tasks done, loop exits
→ Action: Check progress.md; identify bottleneck; address before resuming
```

## Running Spec-Loop Effectively

### Small Specs (5-10 tasks)
Run in one batch:
```bash
bash scripts/spec-loop.sh --spec-name my-feature --max-iterations 15
```

### Medium Specs (15-25 tasks)
Use multiple batches (10-15 iterations each):
```bash
# Batch 1
bash scripts/spec-loop.sh --spec-name my-feature --max-iterations 15

# Monitor progress
cat .claude/specs/my-feature/progress.md | tail -20

# Batch 2 (will auto-resume from checkpoints)
bash scripts/spec-loop.sh --spec-name my-feature --max-iterations 15
```

### Large Specs (40+ tasks)
Consider:
1. **Test-first approach** — Pass guideline: write tests before code
2. **Parallel runs** — Run independent specs in parallel on separate branches
3. **Smaller batches** — 8-10 tasks per run to catch issues early

## Error Recovery

If a loop fails mid-run:

1. **Check what happened:**
   ```bash
   cat .claude/specs/<SPEC>/progress.md | tail -30
   git log --oneline -10
   ```

2. **Identify the blocker:**
   - Is the build broken?
   - Is an API down?
   - Did the rate limit hit?
   - Is there missing config?

3. **Fix it locally:**
   ```bash
   # Fix the root cause, commit your changes
   git add .
   git commit -m "fix: resolve blocker preventing loop resumption"
   ```

4. **Resume the loop:**
   ```bash
   # Checkpoints skip already-completed tasks
   bash scripts/spec-loop.sh --spec-name my-feature --max-iterations 15
   ```

## Tips

- **Monitor in parallel**: Open another terminal and tail progress.md while the loop runs
- **Batch size matters**: 10-15 iterations per run balances throughput with error visibility
- **Build must pass**: Loop won't proceed if build is broken (by design)
- **Integration sweep is mandatory**: When all tasks complete, loop runs final validation sweep before marking COMPLETE
- **Trust the gates**: If verification gates fail 2x, the loop skips (acceptable); don't manually retry
