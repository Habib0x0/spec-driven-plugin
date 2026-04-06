# Headless Orchestration for Spec-Loop Automation

Alternative to iterative spec-loop execution for cleaner, more robust parallel automation.

## Current State (Iterative Spec-Loop)

Your plugin's default approach:
- Runs iteratively (one task per iteration)
- Checkpointing via git
- Verification gates built-in
- Human-friendly progress tracking

**Strengths:** Clear progress visibility, easy to pause/resume, human oversight  
**Limitations:** Sequential (one task at a time), slower for independent tasks

## Headless Alternative

Use Claude Code's **headless mode** (non-interactive CLI) to run multiple independent tasks in parallel with structured subprocess orchestration.

### Basic Pattern

```bash
#!/bin/bash
# Direct claude CLI invocation with explicit permissions

Task="Implement task: $TASK_DESCRIPTION"
Output="results/$TASK_ID.json"

claude \
  -p "$Task" \
  --allowedTools "Edit,Read,Write,Bash,Grep" \
  --dangerously-skip-permissions \
  > "$Output" 2>&1

EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
  echo "✓ Task $TASK_ID completed"
  touch "$Output.done"
else
  echo "✗ Task $TASK_ID failed with exit code $EXIT_CODE"
fi
```

### Advantages Over Iterative Loop

| Aspect | Spec-Loop | Headless |
|--------|-----------|----------|
| **Execution** | Sequential (1 task/iteration) | Parallel (multiple simultaneously) |
| **Output** | Appended to progress.md | Structured files (JSON/markdown) |
| **Process Control** | Shell script manages iteration | Direct subprocess spawning |
| **Scalability** | ~10-15 tasks per batch | Unlimited (system resource-limited) |
| **CI/CD** | Requires manual monitoring | Native integration |
| **Parallelization** | Limited by Claude iterations | True parallelism |

## Parallel Orchestration Pattern

### Example: Running 5 Tasks in Parallel

```bash
#!/bin/bash

SPEC_DIR=".claude/specs/my-feature"
OUTPUT_DIR="$(pwd)/task-results"
mkdir -p "$OUTPUT_DIR"

# Array of task IDs
TASKS=("T-1" "T-2" "T-3" "T-4" "T-5")
PIDS=()

# Spawn all tasks in parallel
for TASK_ID in "${TASKS[@]}"; do
  (
    # Subshell for each task
    echo "Starting $TASK_ID..."
    
    claude -p "
# Spec: $SPEC_DIR/requirements.md
# Design: $SPEC_DIR/design.md
# Task: $(grep -A 5 \"^### $TASK_ID\" $SPEC_DIR/tasks.md)

Implement this task. Mark complete only when verified end-to-end.
" \
      --allowedTools "Edit,Read,Write,Bash,Grep" \
      --dangerously-skip-permissions \
      > "$OUTPUT_DIR/$TASK_ID.json" 2>&1
    
    EXIT=$?
    if [ $EXIT -eq 0 ]; then
      touch "$OUTPUT_DIR/$TASK_ID.done"
      echo "✓ $TASK_ID complete"
    else
      echo "✗ $TASK_ID failed (exit: $EXIT)"
    fi
  ) &
  
  PIDS+=($!)
done

# Wait for all tasks
echo "Waiting for ${#PIDS[@]} tasks..."
for PID in "${PIDS[@]}"; do
  wait $PID
done

# Validate all completed
COMPLETED=$(ls "$OUTPUT_DIR"/*.done 2>/dev/null | wc -l)
echo "Completed: $COMPLETED / ${#TASKS[@]}"

if [ "$COMPLETED" -eq "${#TASKS[@]}" ]; then
  echo "✓ All tasks passed!"
  exit 0
else
  echo "✗ Some tasks failed"
  exit 1
fi
```

### With Checkpoint Recovery

```bash
#!/bin/bash

SPEC_DIR=".claude/specs/my-feature"
OUTPUT_DIR="$(pwd)/task-results"
CHECKPOINT_DIR=".spec-checkpoints"
mkdir -p "$OUTPUT_DIR" "$CHECKPOINT_DIR"

for TASK_ID in "${TASKS[@]}"; do
  # Skip if already done
  if [ -f "$CHECKPOINT_DIR/$TASK_ID.done" ]; then
    echo "Task $TASK_ID already complete, skipping..."
    continue
  fi

  # Run task...
  claude -p "..." > "$OUTPUT_DIR/$TASK_ID.json" 2>&1
  
  if [ $? -eq 0 ]; then
    touch "$CHECKPOINT_DIR/$TASK_ID.done"
    echo "✓ $TASK_ID complete (checkpoint saved)"
  fi
done
```

## Monitoring & Diagnostics

### Real-Time Status

```bash
#!/bin/bash
# Watch progress while tasks run

while true; do
  clear
  echo "=== Task Status ==="
  echo "Completed: $(ls task-results/*.done 2>/dev/null | wc -l)"
  echo "Failed: $(ls task-results/*.failed 2>/dev/null | wc -l)"
  echo ""
  echo "Active tasks:"
  ps aux | grep "claude -p" | grep -v grep
  sleep 5
done
```

### Collect Results

```bash
#!/bin/bash

echo "# Task Results" > task-summary.md
for RESULT in task-results/*.json; do
  TASK=$(basename "$RESULT" .json)
  STATUS=$(grep '"status"' "$RESULT" | head -1)
  echo "## $TASK" >> task-summary.md
  echo "Status: $STATUS" >> task-summary.md
  echo "" >> task-summary.md
done
```

### Error Recovery

```bash
#!/bin/bash

# Re-run failed tasks
for FAILED in task-results/*.failed; do
  TASK=$(basename "$FAILED" .failed)
  echo "Retrying $TASK..."
  
  rm "$FAILED"
  # Re-run the task...
done
```

## Integration With Spec-Loop

**Current approach (spec-loop.sh):**
- Runs iteratively (one task per iteration)
- Checkpointing via git
- Verification gates built-in

**Headless approach (parallel):**
- All ready tasks run in parallel
- Checkpoint via file markers
- Verification can run in post-merge phase

### Hybrid Approach (Recommended)

```bash
#!/bin/bash
# Best of both: iterative planning, parallel execution

# Phase 1: Run spec-loop normally for first batch (10-15 tasks)
bash scripts/spec-loop.sh --spec-name my-feature --max-iterations 10

# Phase 2: For remaining independent tasks, use parallel approach
TASKS=$(grep 'Status.*pending' .claude/specs/my-feature/tasks.md | wc -l)
if [ "$TASKS" -gt 10 ]; then
  echo "Many tasks remaining. Switching to parallel mode..."
  bash scripts/parallel-exec.sh my-feature
fi

# Phase 3: Merge results and run final validation
bash scripts/post-merge-validate.sh my-feature
```

## When to Use Headless

### Good Fit

- ✅ Large spec with 20+ independent tasks
- ✅ You want structured, auditable output
- ✅ Need to integrate with CI/CD
- ✅ Running on servers without tmux
- ✅ Prefer explicit permission lists

### Stick with Spec-Loop

- ✅ Smaller specs (5-10 tasks)
- ✅ Complex inter-task dependencies
- ✅ Real-time human oversight needed
- ✅ Verification gates catch regressions
- ✅ Progress.md provides good audit trail

## Example: Full Automation Script

```bash
#!/bin/bash
set -e

SPEC_NAME=$1
if [ -z "$SPEC_NAME" ]; then
  echo "Usage: $0 <spec-name>"
  exit 1
fi

SPEC_DIR=".claude/specs/$SPEC_NAME"
OUTPUT_DIR="task-results-$SPEC_NAME"
mkdir -p "$OUTPUT_DIR"

echo "=== Spec Headless Orchestrator ==="
echo "Spec: $SPEC_NAME"
echo "Output: $OUTPUT_DIR"
echo ""

# Preflight
echo "Preflight checks..."
git remote -v | head -1 || { echo "✗ No git remote"; exit 1; }
[ -d "$SPEC_DIR" ] || { echo "✗ Spec not found"; exit 1; }

# Parse tasks from tasks.md
TASKS=($(grep '^### T-' "$SPEC_DIR/tasks.md" | sed 's/^### //'))

echo "Found ${#TASKS[@]} tasks"
echo ""

# Run each task
for TASK_ID in "${TASKS[@]}"; do
  if [ -f "$OUTPUT_DIR/$TASK_ID.done" ]; then
    echo "SKIP $TASK_ID (already complete)"
    continue
  fi
  
  echo "RUN  $TASK_ID..."
  
  if claude -p "Implement task $TASK_ID from spec $SPEC_NAME" \
      --allowedTools "Edit,Read,Write,Bash,Grep" \
      --dangerously-skip-permissions \
      > "$OUTPUT_DIR/$TASK_ID.json" 2>&1; then
    touch "$OUTPUT_DIR/$TASK_ID.done"
    echo "✓    $TASK_ID complete"
  else
    echo "✗    $TASK_ID failed"
  fi
done

echo ""
COMPLETED=$(ls "$OUTPUT_DIR"/*.done 2>/dev/null | wc -l)
echo "Completed: $COMPLETED / ${#TASKS[@]}"

if [ "$COMPLETED" -eq "${#TASKS[@]}" ]; then
  echo "✓ All tasks complete!"
  exit 0
else
  echo "✗ Some tasks failed"
  exit 1
fi
```

## Recommendation

For the spec-driven-plugin:

1. **Keep spec-loop.sh as-is** — Excellent for guided, iterative work
2. **Offer headless as optional** — Document in HEADLESS_ORCHESTRATION.md
3. **Create `scripts/parallel-exec.sh`** — Uses headless pattern for independent tasks (optional, in examples)
4. **Document hybrid approach** — Which approach fits which scenario

This gives users flexibility: iterative refinement via spec-loop, or parallel power via headless for large projects.
