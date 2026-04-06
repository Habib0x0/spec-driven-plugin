# Advanced Patterns for Spec-Driven Workflows

Based on Claude Code usage analysis, these patterns unlock autonomous, resilient, and parallel spec execution at scale.

## Pattern 1: Test-Driven Autonomous Implementation Loops

**Problem:** 40% of spec-loop completion rates are bottlenecked by buggy code that requires multiple fix iterations.

**Pattern:** Enforce test-first development during spec execution.

### Implementation

Pass this guideline to Claude when running spec-loops:

```
For each task:
1. Write failing tests first based on spec requirements
2. Implement the minimum code to pass those tests
3. Run the test suite and iterate until all tests pass
4. Only mark complete when tests are green

If you hit an error you can't resolve in 3 attempts, skip it and log.
Start by reading the spec and listing all tasks with their test criteria.
```

### Why This Works

- Tests are a contract—if they pass, the feature works
- Prevents "mostly working" code from marching forward
- Catches regressions immediately
- Reduces verification gate failures (your spec-loop already has these; tests make them pass more often)

### Preconditions

- Project must have a test suite (unit, integration, or e2e)
- Tests must run quickly (<2s per task for fast iteration)
- Use `--max-iterations` in smaller batches (8-10 tasks) when test-first to catch issues early

---

## Pattern 2: Parallel Agent Teams With Structured Handoffs

**Problem:** Your 67 multi-clauding events show you're already running parallel sessions. But coordination is manual (tmux-based). This pattern makes it automatic.

**Pattern:** Use Claude's Agent spawning with structured task files and coordinator logic.

### How It Works

1. **Orchestrator Agent** (spawned once)
   - Reads the spec and breaks it into independent parallel tasks
   - Writes task briefs to `/tmp/tasks/task-N.md` (or `.claude/tasks/`)
   - Spawns sub-agents for each task
   - Monitors for completion markers

2. **Worker Agents** (spawned in parallel)
   - Each gets one task file and relevant source files
   - Works independently
   - Writes completion marker when done: `/tmp/tasks/task-N-done.md`

3. **Merge Phase** (orchestrator)
   - Validates outputs don't conflict
   - Resolves merge issues
   - Runs full test suite
   - Reports completion

### Example Workflow

```bash
# Start the orchestrator agent with this prompt:
claude -p "
Act as a team coordinator for [PROJECT].

1. Break the spec into 5-8 independent parallel tasks.
2. For each task, write a brief to .claude/tasks/task-N.md with:
   - What you're implementing (be specific)
   - Which files to modify
   - Acceptance criteria
3. Spawn sub-agents using the Agent tool for each task.
4. Monitor .claude/tasks/task-N-done.md files.
5. When all agents finish, validate and merge results.
6. Run the test suite and report completion.
" --dangerously-skip-permissions
```

### Preconditions

- Tasks must be **independent** (minimal cross-dependencies)
- Each task should map to a specific file or feature boundary
- Sub-agents need enough context (relevant source files)
- Test suite must be comprehensive (validation step)

### Benefits

- Parallelizes Claude across multiple streams (faster)
- Structured handoffs reduce communication friction
- Explicit completion markers prevent orphaned tasks
- Validation gates catch merge conflicts early

---

## Pattern 3: Self-Correcting Security Research Pipelines

**Problem:** Your 17 security testing sessions frequently stalled on model errors, API failures, and stuck loops with no recovery mechanism.

**Pattern:** Checkpoint-based pipeline that survives rate limits and tool failures.

### How It Works

Structure reconnaissance as **phases** that write to disk:

```
Phase 1: Subdomain enumeration & port scanning
  → Save to: recon/phase1-results.json
  → If exists, skip (resumable)

Phase 2: Service fingerprinting
  → Save to: recon/phase2-results.json
  → Only processes services from phase1

Phase 3: Vulnerability analysis
  → Save to: recon/phase3-results.json
  → Analyzes services from phase2

Phase 4: Report compilation
  → Reads all phases, compiles findings
  → Each finding includes command for verification
```

### Implementation

```bash
# Claude generates and iterates on this pipeline:
#!/bin/bash
TARGET=$1
RECON_DIR="recon/$TARGET"
mkdir -p "$RECON_DIR"

# Phase 1: Only run if phase1 output doesn't exist
if [ ! -f "$RECON_DIR/phase1-results.json" ]; then
  echo "Running Phase 1..."
  # subdomain enumeration, port scanning
  # results to phase1-results.json
else
  echo "Phase 1 already complete, skipping..."
fi

# Phase 2: Only run if phase2 doesn't exist
if [ ! -f "$RECON_DIR/phase2-results.json" ]; then
  echo "Running Phase 2..."
  # service fingerprinting on phase1 results
  # results to phase2-results.json
else
  echo "Phase 2 already complete, skipping..."
fi

# ... continue for all phases

# Status tracker
echo "## Progress $(date)" >> "$RECON_DIR/status.md"
echo "- Phase 1: $([ -f phase1-results.json ] && echo 'DONE' || echo 'PENDING')" >> "$RECON_DIR/status.md"
# ... etc
```

### Key Rules

- **Before each phase:** Check if output file exists. If yes, skip (resumable).
- **If a tool fails 3x:** Log the error and move to next target/phase (don't get stuck).
- **All findings must include evidence:** The command that discovered it (for re-verification).
- **Progress tracker:** Write to status.md after each phase (visible during execution).

### Benefits

- Survives rate limits (pause, wait, resume)
- Survives API errors (move on, don't retry indefinitely)
- Full audit trail (every phase logged with evidence)
- Resumable (no lost progress on failure)
- Can be re-run incrementally (phase 3 can be re-run without phases 1-2)

---

## Pattern 4: Error Loop Trap Prevention

**Problem:** Your sessions show repeated instances of Claude retrying the same failing approach (37 min on model resolution, 267 min on API errors).

**Pattern:** Explicit retry limits with clear diagnostic output.

### Quick Implementation

When asking Claude to fix a config or integration issue:

```
Try this approach twice max. If it fails both times, stop and tell me:
(1) What exact error you're hitting
(2) What you think the root cause is
(3) What information/access you'd need to fix it
```

### Why This Works

- **Bounded effort**: 2 attempts max, not infinite retries
- **Early diagnosis**: Claude explains what's blocking, not just "trying again"
- **Clear handoff**: You get the info you need to unblock manually

### For Spec-Loops Specifically

Add to your spec-loop prompt:

```
If any task fails 2 times with the same error, skip it and log to progress.md:
- What task failed
- What error occurred
- What you would try next (but can't)
- What's likely blocking it
```

Your spec-loop.sh already does this with verification gates. The pattern is to **trust the gate**, not retry manually.

---

## When to Use Each Pattern

| Pattern | Use When | Complexity |
|---------|----------|-----------|
| **Test-First Loops** | Projects with test suites; you want guaranteed working code | Medium |
| **Parallel Teams** | 5+ independent tasks; want speed; have well-defined boundaries | High |
| **Checkpoint Pipelines** | Long-running workflows (recon, analysis); prone to API failures | High |
| **Error Loop Prevention** | Any time Claude gets stuck retrying; needs clear diagnostic output | Low |

---

## Recommended Implementation Order

1. **Start with Error Loop Prevention** (low effort, immediate payoff)
2. **Layer in Test-First** if your project has tests
3. **Move to Parallel Teams** once you're comfortable with structured task handoffs
4. **Build Checkpoint Pipelines** for security/research workflows

---

## Integration With Spec-Driven Plugin

All four patterns work **within** your existing spec-loop infrastructure:

- **Test-First Loops**: Pass test guidelines in `/spec-exec` or `/spec-loop` prompts
- **Parallel Teams**: Can be triggered after a major spec completes (e.g., design system with 10 components)
- **Checkpoint Pipelines**: Use for `/spec-debug` or post-implementation research phases
- **Error Loop Prevention**: Built into CLAUDE.md rules (see main docs)

No changes needed to your scripts. These are **Claude behavior patterns**, not infrastructure changes.

---

## Measuring Success

After implementing these patterns, track:

- **Spec-loop completion rate** (target: >80% tasks complete per run)
- **Buggy code incidents** (track in progress.md; should decrease)
- **Loop duration** (test-first may take longer initially, but fewer iterations overall)
- **Recovery success** (checkpoint resume without manual intervention)

Your report showed 45 "mostly achieved" outcomes. These patterns target "fully achieved."
