# Design: Model-Agnostic Routing

> Profile-informed design. Project profile last updated: 2026-04-17.

## Overview

This is a focused refactor that replaces snapshot-pinned model IDs with tier aliases across 11 agent files, adds env-var override instructions to 5 command files, creates a new backend detection shell helper sourced by 8 scripts, creates one new documentation page, updates version-specific prose in approximately 25 documentation files, and bumps the plugin version. No new architecture is introduced -- the change surfaces existing Claude Code capabilities (tier aliases, Task tool model override) that were previously hardcoded.

## Architecture

### Where Routing Decisions Happen

Model routing in the plugin occurs at three distinct layers. This refactor touches all three but does not change the fundamental flow:

```
Layer 1: Agent Frontmatter (agents/*.md)
  model: opus | sonnet | haiku           <-- tier alias (was snapshot ID)
  |
  v
Layer 2: Command Prompt (commands/*.md)
  Task tool invocation with optional      <-- reads SPEC_MODEL_* env var,
  model: parameter override                   passes to Task if set
  |
  v
Layer 3: Shell Scripts (scripts/*.sh)
  claude --dangerously-skip-permissions   <-- inherits session model;
  + detect-backend.sh banner                  banner is informational only
```

### Data Flow

```
User invokes /spec <name>
  |
  v
commands/spec.md (inline prompt)
  |
  +--> Check env: SPEC_MODEL_PLANNER set?
  |      yes --> Task(agent=spec-planner, model=$SPEC_MODEL_PLANNER)
  |      no  --> Task(agent=spec-planner)  // uses frontmatter: opus
  |
  +--> Check env: SPEC_MODEL_TASKER set?
  |      yes --> Task(agent=spec-tasker, model=$SPEC_MODEL_TASKER)
  |      no  --> Task(agent=spec-tasker)   // uses frontmatter: sonnet
  |
  +--> (same pattern for spec-validator, spec-scanner, spec-planner in fix loop)
  |
  v
Summary displayed to user


User invokes spec-exec.sh
  |
  v
source scripts/lib/detect-backend.sh
  |
  +--> is_anthropic_backend()?
  |      yes --> (no banner, proceed normally)
  |      no  --> print banner to stderr (once), proceed normally
  |
  v
claude --dangerously-skip-permissions -p "$(cat $PROMPT_FILE)"
  (inherits session model -- no --model flag needed)
```

## Components

### Component 1: Backend Detection Helper

**File**: `scripts/lib/detect-backend.sh` (NEW)

**Purpose**: Provide a reusable shell function for detecting whether the user is on an Anthropic backend, and print a one-time optimization notice when not.

**Responsibilities**:
- Export `is_anthropic_backend()` function
- Print optimization notice to stderr on first invocation when non-Anthropic backend detected
- Respect `SPEC_QUIET=1` suppression
- Guard against multiple sourcing within a single process

**Traceability**: US-2, US-3, NFR-1, NFR-2, NFR-3, NFR-5

**Implementation**:

```bash
#!/usr/bin/env bash
# lib/detect-backend.sh -- Backend detection and optimization notice
# Source this file; do not execute directly.

# is_anthropic_backend()
# Returns 0 if backend is Anthropic (or unset), 1 otherwise.
# Pure string check -- no network calls.
is_anthropic_backend() {
  if [ -z "${ANTHROPIC_BASE_URL:-}" ]; then
    return 0
  fi
  case "$ANTHROPIC_BASE_URL" in
    *anthropic.com*) return 0 ;;
    *) return 1 ;;
  esac
}

# Print notice once per process. Guard variable prevents repeat printing
# if this file is sourced multiple times.
if [ -z "${_SPEC_BACKEND_NOTICE_SHOWN:-}" ]; then
  _SPEC_BACKEND_NOTICE_SHOWN=1
  if ! is_anthropic_backend && [ "${SPEC_QUIET:-}" != "1" ]; then
    cat >&2 <<NOTICE

[spec-driven] Non-Anthropic backend detected
  URL: ${ANTHROPIC_BASE_URL}

  The spec-driven plugin uses tiered model routing. You can optimize
  agent performance by mapping each tier to a model your router supports:

    export SPEC_MODEL_PLANNER=<your-deep-reasoning-model>
    export SPEC_MODEL_TASKER=<your-fast-coding-model>
    export SPEC_MODEL_VALIDATOR=<your-fast-coding-model>
    export SPEC_MODEL_IMPLEMENTER=<your-fast-coding-model>
    export SPEC_MODEL_TESTER=<your-fast-coding-model>
    export SPEC_MODEL_REVIEWER=<your-deep-reasoning-model>
    export SPEC_MODEL_DEBUGGER=<your-lightweight-model>
    export SPEC_MODEL_SCANNER=<your-fast-coding-model>
    export SPEC_MODEL_ACCEPTOR=<your-fast-coding-model>
    export SPEC_MODEL_DOCUMENTER=<your-fast-coding-model>
    export SPEC_MODEL_CONSULTANT=<your-fast-coding-model>

  Example: export SPEC_MODEL_PLANNER=deepseek-v3

  See: docs/advanced/model-routing.md
  Suppress this notice: export SPEC_QUIET=1

NOTICE
  fi
fi
```

**Conventions followed**:
- File placed in `scripts/lib/` alongside `checkpoint.sh`, `deps.sh`, `verify.sh` (PAT-3 library convention)
- Uses `set -e` implicitly (sourced into parent script's context, which uses `set -e`)
- No shebang needed since this is sourced, but `#!/usr/bin/env bash` included for editor support per existing `deps.sh` convention (line 1 of `scripts/lib/deps.sh`)

---

### Component 2: Agent Frontmatter Refactor (11 files)

**Files**: All files in `agents/*.md`

**Purpose**: Replace snapshot-pinned model IDs with tier aliases.

**Traceability**: US-1

**Changes per file**:

| File | Current `model:` | New `model:` |
|------|-----------------|-------------|
| `agents/spec-planner.md` | `claude-opus-4-6` | `opus` |
| `agents/spec-reviewer.md` | `claude-opus-4-6` | `opus` |
| `agents/spec-tasker.md` | `claude-sonnet-4-6` | `sonnet` |
| `agents/spec-validator.md` | `claude-sonnet-4-6` | `sonnet` |
| `agents/spec-implementer.md` | `claude-sonnet-4-6` | `sonnet` |
| `agents/spec-tester.md` | `claude-sonnet-4-6` | `sonnet` |
| `agents/spec-acceptor.md` | `claude-sonnet-4-6` | `sonnet` |
| `agents/spec-consultant.md` | `claude-sonnet-4-6` | `sonnet` |
| `agents/spec-documenter.md` | `claude-sonnet-4-6` | `sonnet` |
| `agents/spec-scanner.md` | `claude-sonnet-4-6` | `sonnet` |
| `agents/spec-debugger.md` | `claude-haiku-4-5-20251001` | `haiku` |

**Additional edits per file**: Update `description:` text to use tier language:
- "This agent runs on Opus for deep reasoning" becomes "This agent runs on the opus tier for deep reasoning"
- "Uses Opus for deep reasoning about subtle issues" becomes "Uses the opus tier for deep reasoning about subtle issues"
- Similar for sonnet/haiku references in description fields

**Regression guards (BUG-1)**:
- `agents/spec-implementer.md`: Only edit the YAML frontmatter (`model:` line, lines within `description:`). Do NOT modify the system prompt body below the `---` closing delimiter.
- `agents/spec-tester.md`: Same constraint.
- `agents/spec-reviewer.md`: Same constraint.

---

### Component 3: Command Prompt Refactor (5 files)

**Files**: `commands/spec.md`, `commands/spec-brainstorm.md`, `commands/spec-refine.md`, `commands/spec-tasks.md`, `commands/spec-validate.md`

**Purpose**: Add env-var override instructions so that when commands spawn agents via the Task tool, they check the relevant `SPEC_MODEL_*` env var and pass it as the `model:` parameter.

**Traceability**: US-4

**Design for `commands/spec.md`**:

This is the most complex command because it spawns multiple agents: `spec-scanner`, `spec-planner`, `spec-tasker`, `spec-validator`. Each spawn point in the prompt needs an override instruction.

Add a new section near the top of the command body (after the Model Routing table):

```markdown
## Model Override

When spawning agents via the Task tool, check the corresponding environment variable.
If set to a non-empty string, pass it as the `model:` parameter to the Task tool:

- spec-scanner: check `SPEC_MODEL_SCANNER`
- spec-planner: check `SPEC_MODEL_PLANNER`
- spec-tasker: check `SPEC_MODEL_TASKER`
- spec-validator: check `SPEC_MODEL_VALIDATOR`

Example: if `SPEC_MODEL_PLANNER` is set, spawn the planner as:
  Task(agent=spec-planner, model=$SPEC_MODEL_PLANNER, prompt=...)

If the env var is unset or empty, omit the model parameter and let the agent's
frontmatter tier alias take effect.
```

**Regression guard (BUG-2)**: The validate-fix loop in Step 4.5 of `commands/spec.md` routes requirement/design issues to `spec-planner` and task issues to `spec-tasker`. The env-var override instruction must be added to both spawn points without changing the routing logic. The override only affects which model is used, not which agent is chosen.

**Design for other commands**:

Each command that spawns agents needs similar instructions. These are simpler since they spawn fewer agents:

- `commands/spec-brainstorm.md`: Spawns `spec-consultant`. Add override check for `SPEC_MODEL_CONSULTANT`.
- `commands/spec-refine.md`: May delegate to planner/tasker. Add override checks for `SPEC_MODEL_PLANNER` and `SPEC_MODEL_TASKER`.
- `commands/spec-tasks.md`: Delegates to tasker. Add override check for `SPEC_MODEL_TASKER`.
- `commands/spec-validate.md`: This command does not spawn agents via Task tool (it runs validation inline). However, if it delegates to `spec-validator` agent, add override check for `SPEC_MODEL_VALIDATOR`. Reading the current file: it uses only `Read`, `Glob`, `Grep` tools -- no Task tool. No agent spawning occurs. **No override needed for this command.**

Revised list of commands needing override instructions: `commands/spec.md`, `commands/spec-brainstorm.md`, `commands/spec-refine.md`, `commands/spec-tasks.md`. (4 commands, not 5.)

**Note**: `commands/spec-validate.md` does not use the Task tool and does not spawn agents, so it does not need model override instructions. However, the `/spec` command's auto-validate step (Step 4.5) does spawn `spec-validator` via Task -- that override is handled in `commands/spec.md`.

---

### Component 4: Shell Script Banner Injection (8 files)

**Files**: `scripts/spec-exec.sh`, `scripts/spec-loop.sh`, `scripts/spec-complete.sh`, `scripts/spec-accept.sh`, `scripts/spec-docs.sh`, `scripts/spec-release.sh`, `scripts/spec-verify.sh`, `scripts/spec-retro.sh`

**Purpose**: Source the backend detection helper so the optimization notice prints when a non-Anthropic backend is detected.

**Traceability**: US-2, US-3

**Change pattern**: Add one line after existing `source` statements near the top of each script:

```bash
source "$SCRIPT_DIR/lib/detect-backend.sh"
```

For scripts that already have a `SCRIPT_DIR` variable and `source` lines (confirmed for `spec-exec.sh` at line 63, `spec-loop.sh` at lines 79-84), the new line goes immediately after the last existing `source` line.

For scripts that do not currently define `SCRIPT_DIR` (`spec-accept.sh`, `spec-docs.sh`, `spec-release.sh`, `spec-verify.sh`, `spec-retro.sh`, `spec-complete.sh`), add:

```bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
```

at the top of the script (after `set -e`), then add the `source` line. Check each script individually -- `spec-complete.sh` already defines `SCRIPT_DIR` at line 3.

**Regression guard (BUG-1)**: For `scripts/spec-exec.sh` and `scripts/spec-loop.sh`, the source line is added to the script preamble, far from the prompt template heredoc. The prompt template content (which contains anti-stub rules) must not be modified.

---

### Component 5: Documentation Refactor

**Purpose**: Replace all version-specific model references with tier-based language.

**Traceability**: US-5

#### 5a. `CLAUDE.md` updates

The Model Routing table (currently at approximately lines 37-50) references specific versions. Update to:

| Agent | Model Tier | Phase | Rationale |
|-------|-----------|-------|-----------|
| spec-planner | opus | Requirements + Design | Deep reasoning for edge cases, security, architecture |
| spec-tasker | sonnet | Task breakdown | Fast, structured decomposition |
| spec-validator | sonnet | Validation | Checklist-based verification |
| spec-implementer | sonnet | Implementation | Writes code for tasks |
| spec-tester | sonnet | Testing | Verifies with Playwright/tests |
| spec-reviewer | opus | Review | Code quality, security, architecture |
| spec-consultant | sonnet | Consultation | Domain expert analysis during brainstorming |
| spec-acceptor | sonnet | Acceptance | Requirement traceability, non-functional verification |
| spec-documenter | sonnet | Documentation | Generates docs from spec and code |
| spec-debugger | haiku | Debug / small fixes | Lightweight targeted fixes |

Also update prose references like "Opus 4.6" to "opus tier" or "deep-reasoning tier" and "Sonnet 4.6" to "sonnet tier" throughout the file.

Add a brief note about env-var overrides in the Model Routing section:

```markdown
Each agent's model can be overridden via environment variable (e.g., `SPEC_MODEL_PLANNER=my-model`).
See `docs/advanced/model-routing.md` for details.
```

#### 5b. `commands/spec.md` Model Routing table

Update the table to remove version numbers:

| Phase | Who | Model Tier | Why |
|-------|-----|-----------|-----|
| Phase 0 Scan | spec-scanner agent | sonnet | Fast multi-file reading |
| Requirements Gathering | /spec command (inline) | Current session model | Interactive -- needs AskUserQuestion |
| Requirements + Design Writing | spec-planner agent | opus | Deep reasoning for edge cases and architecture |
| Tasks | spec-tasker agent | sonnet | Fast, structured task generation |
| Validation | spec-validator agent | sonnet | Checklist-based verification |

#### 5c. Agent `description:` fields (11 files)

Each agent's `description:` in YAML frontmatter may reference specific versions. Grep results show these files have version references: `spec-planner.md`, `spec-tasker.md`, `spec-reviewer.md`. Update all instances from version-specific to tier-based language. Examples:

- "This agent runs on Opus for deep reasoning" -> "This agent runs on the opus tier for deep reasoning"
- "This agent runs on Sonnet for fast" -> "This agent runs on the sonnet tier for fast"

Also update the system prompt body of `spec-planner.md` line 41: "You run on Opus for deep reasoning" -> "You run on the opus tier for deep reasoning"

#### 5d. Documentation files under `docs/`

Files containing version-specific model references (from grep results, excluding archived specs):

- `docs/agents/index.md`
- `docs/agents/spec-planner.md`
- `docs/agents/spec-reviewer.md`
- `docs/commands/index.md`
- `docs/commands/spec.md`
- `docs/workflow/overview.md`
- `docs/workflow/design.md`
- `docs/workflow/execution.md`
- `docs/workflow/tasks.md`
- `docs/workflow/requirements.md`
- `docs/getting-started/concepts.md`
- `docs/getting-started/quick-start.md`
- `docs/advanced/extending.md`

For each file, replace patterns:
- `Opus 4.6` / `Opus 4\.6` -> `opus tier` or `the opus tier`
- `Sonnet 4.6` / `Sonnet 4\.6` -> `sonnet tier` or `the sonnet tier`
- `Haiku 4.5` / `Haiku 4\.5` -> `haiku tier` or `the haiku tier`
- `claude-opus-4-6` -> `opus`
- `claude-sonnet-4-6` -> `sonnet`
- `claude-haiku-4-5-20251001` -> `haiku`

Context-sensitive: in table cells showing a model column, use bare `opus`/`sonnet`/`haiku`. In prose, use "the opus tier", "the sonnet tier", etc.

#### 5e. New file: `docs/advanced/model-routing.md`

**Purpose**: Comprehensive guide for model routing, env-var overrides, and non-Anthropic backend configuration.

**Contents**:

1. **Introduction**: The plugin uses a three-tier model system. Agents are assigned to tiers based on the reasoning depth required.

2. **Tier System**:
   - `opus` -- Deep reasoning tier. Used for requirements analysis, architecture design, code review. Agents: spec-planner, spec-reviewer.
   - `sonnet` -- Fast coding tier. Used for implementation, testing, task generation, validation. Agents: spec-tasker, spec-validator, spec-implementer, spec-tester, spec-acceptor, spec-consultant, spec-documenter, spec-scanner.
   - `haiku` -- Lightweight tier. Used for quick fixes and debugging. Agents: spec-debugger.

3. **How Tier Resolution Works**: Agent frontmatter contains `model: opus` (or `sonnet`/`haiku`). Claude Code resolves the alias to the latest model in that tier at runtime.

4. **Env-Var Overrides**: Full table of 11 env vars (same as US-4 AC-4 table). Precedence: env var > frontmatter tier alias. Env vars are read by command prompts at agent spawn time.

5. **Backend Detection**: Explain the `ANTHROPIC_BASE_URL` check. Logic: unset or contains `anthropic.com` = Anthropic backend; anything else = non-Anthropic. No network calls.

6. **Optimization Notice**: Explain the one-time stderr notice, what it contains, and how to suppress with `SPEC_QUIET=1`.

7. **Router Configuration Examples**:

   **Claude Code Router (CCR)**:
   ```bash
   export SPEC_MODEL_PLANNER=deepseek-v3
   export SPEC_MODEL_REVIEWER=deepseek-v3
   export SPEC_MODEL_TASKER=qwen3-coder
   export SPEC_MODEL_VALIDATOR=qwen3-coder
   export SPEC_MODEL_IMPLEMENTER=qwen3-coder
   export SPEC_MODEL_TESTER=qwen3-coder
   export SPEC_MODEL_ACCEPTOR=qwen3-coder
   export SPEC_MODEL_CONSULTANT=qwen3-coder
   export SPEC_MODEL_DOCUMENTER=qwen3-coder
   export SPEC_MODEL_SCANNER=qwen3-coder
   export SPEC_MODEL_DEBUGGER=qwen3-235b-a22b
   ```

   **LiteLLM**:
   ```bash
   # LiteLLM model names follow provider/model convention
   export SPEC_MODEL_PLANNER=deepseek/deepseek-chat
   export SPEC_MODEL_REVIEWER=deepseek/deepseek-chat
   export SPEC_MODEL_IMPLEMENTER=openai/qwen3-coder
   # ... (full list)
   ```

   **opencode**:
   ```bash
   # opencode maps to provider-specific model IDs
   export SPEC_MODEL_PLANNER=deepseek-v3
   export SPEC_MODEL_IMPLEMENTER=qwen3-coder
   # ... (full list)
   ```

8. **Restoring Version Pinning**: Users who want to pin a specific snapshot can use env vars: `export SPEC_MODEL_PLANNER=claude-opus-4-6`. This overrides the tier alias and locks to a specific version.

---

### Component 6: Version Bump (2 files)

**Files**: `.claude-plugin/plugin.json`, `skills/spec-workflow/SKILL.md`

**Purpose**: Bump version from `5.0.3` to `5.1.0`.

**Traceability**: US-6

**Changes**:

`.claude-plugin/plugin.json` line 3:
```json
"version": "5.1.0",
```

`skills/spec-workflow/SKILL.md` frontmatter line 4:
```yaml
version: 5.1.0
```

---

## Env-Var Contract

### Detection Variables

| Variable | Purpose | Values |
|----------|---------|--------|
| `ANTHROPIC_BASE_URL` | Backend URL (set by user/router) | URL string or unset |
| `SPEC_QUIET` | Suppress optimization notice | `1` to suppress; any other value or unset = show notice |

### Model Override Variables

| Variable | Agent | Default Tier |
|----------|-------|-------------|
| `SPEC_MODEL_PLANNER` | spec-planner | opus |
| `SPEC_MODEL_TASKER` | spec-tasker | sonnet |
| `SPEC_MODEL_VALIDATOR` | spec-validator | sonnet |
| `SPEC_MODEL_IMPLEMENTER` | spec-implementer | sonnet |
| `SPEC_MODEL_TESTER` | spec-tester | sonnet |
| `SPEC_MODEL_REVIEWER` | spec-reviewer | opus |
| `SPEC_MODEL_DEBUGGER` | spec-debugger | haiku |
| `SPEC_MODEL_SCANNER` | spec-scanner | sonnet |
| `SPEC_MODEL_ACCEPTOR` | spec-acceptor | sonnet |
| `SPEC_MODEL_DOCUMENTER` | spec-documenter | sonnet |
| `SPEC_MODEL_CONSULTANT` | spec-consultant | sonnet |

### Precedence

```
SPEC_MODEL_* env var (if set and non-empty)
  |
  v (overrides)
Agent frontmatter model: field (tier alias)
  |
  v (resolved by Claude Code runtime)
Actual model used for the agent
```

---

## Sequence Diagrams

### Sequence 1: /spec Command with Env-Var Override

```
User                   commands/spec.md          Task Tool           spec-planner
 |                          |                       |                     |
 |-- /spec my-feature ----->|                       |                     |
 |                          |                       |                     |
 |                    [check $SPEC_MODEL_PLANNER]   |                     |
 |                    [value = "deepseek-v3"]        |                     |
 |                          |                       |                     |
 |                          |-- Task(agent=planner, |                     |
 |                          |   model=deepseek-v3,  |                     |
 |                          |   prompt=...)-------->|                     |
 |                          |                       |-- spawn agent ----->|
 |                          |                       |   (model override)  |
 |                          |                       |                     |
 |                          |                       |<-- result ----------|
 |                          |<-- result ------------|                     |
 |<-- summary --------------|                       |                     |
```

### Sequence 2: Shell Script with Backend Detection

```
User                    spec-exec.sh          detect-backend.sh        claude CLI
 |                          |                       |                     |
 |-- ./spec-exec.sh ------->|                       |                     |
 |                          |                       |                     |
 |                    [source detect-backend.sh]--->|                     |
 |                          |                 [check ANTHROPIC_BASE_URL]  |
 |                          |                 [= http://localhost:4000]   |
 |                          |                 [not anthropic.com]         |
 |                          |                 [SPEC_QUIET != 1]           |
 |                          |                 [print banner to stderr]    |
 |                          |<----(sourced, back in spec-exec.sh)         |
 |                          |                                             |
 |<-- banner (stderr) ------|                                             |
 |                          |                                             |
 |                          |-- claude -p "$PROMPT" --------------------->|
 |                          |   (inherits session model, no --model)      |
 |                          |<-- output ----------------------------------|
 |<-- output (stdout) ------|                                             |
```

### Sequence 3: Direct Anthropic (No Change Path)

```
User                    spec-exec.sh          detect-backend.sh        claude CLI
 |                          |                       |                     |
 |-- ./spec-exec.sh ------->|                       |                     |
 |                          |                       |                     |
 |                    [source detect-backend.sh]--->|                     |
 |                          |                 [ANTHROPIC_BASE_URL unset]  |
 |                          |                 [is_anthropic_backend = 0]  |
 |                          |                 [no banner]                 |
 |                          |<----(sourced, back in spec-exec.sh)         |
 |                          |                                             |
 |                          |-- claude -p "$PROMPT" --------------------->|
 |                          |<-- output ----------------------------------|
 |<-- output (stdout) ------|                                             |
```

---

## Complete File Change List

### New Files

| File | Component | Traceability |
|------|-----------|-------------|
| `scripts/lib/detect-backend.sh` | Backend detection helper | US-2, US-3 |
| `docs/advanced/model-routing.md` | Model routing documentation | US-5 |

### Modified Files -- Agent Frontmatter (model: field + description:)

| File | Change | Traceability |
|------|--------|-------------|
| `agents/spec-planner.md` | `model: opus`, update description + system prompt tier references | US-1 |
| `agents/spec-reviewer.md` | `model: opus`, update description tier references | US-1 |
| `agents/spec-tasker.md` | `model: sonnet`, update description tier references | US-1 |
| `agents/spec-validator.md` | `model: sonnet`, update description tier references | US-1 |
| `agents/spec-implementer.md` | `model: sonnet`, update description tier references | US-1 |
| `agents/spec-tester.md` | `model: sonnet`, update description tier references | US-1 |
| `agents/spec-acceptor.md` | `model: sonnet`, update description tier references | US-1 |
| `agents/spec-consultant.md` | `model: sonnet`, update description tier references | US-1 |
| `agents/spec-documenter.md` | `model: sonnet`, update description tier references | US-1 |
| `agents/spec-scanner.md` | `model: sonnet`, update description tier references | US-1 |
| `agents/spec-debugger.md` | `model: haiku`, update description tier references | US-1 |

### Modified Files -- Command Prompts (env-var override instructions)

| File | Change | Traceability |
|------|--------|-------------|
| `commands/spec.md` | Add Model Override section, update routing table | US-4, US-5 |
| `commands/spec-brainstorm.md` | Add override instruction for spec-consultant | US-4 |
| `commands/spec-refine.md` | Add override instruction for spec-planner, spec-tasker | US-4 |
| `commands/spec-tasks.md` | Add override instruction for spec-tasker | US-4 |

### Modified Files -- Shell Scripts (source detect-backend.sh)

| File | Change | Traceability |
|------|--------|-------------|
| `scripts/spec-exec.sh` | Add `source` line for detect-backend.sh | US-2, US-3 |
| `scripts/spec-loop.sh` | Add `source` line for detect-backend.sh | US-2, US-3 |
| `scripts/spec-complete.sh` | Add `source` line for detect-backend.sh | US-2, US-3 |
| `scripts/spec-accept.sh` | Add `SCRIPT_DIR` + `source` line for detect-backend.sh | US-2, US-3 |
| `scripts/spec-docs.sh` | Add `SCRIPT_DIR` + `source` line for detect-backend.sh | US-2, US-3 |
| `scripts/spec-release.sh` | Add `SCRIPT_DIR` + `source` line for detect-backend.sh | US-2, US-3 |
| `scripts/spec-verify.sh` | Add `SCRIPT_DIR` + `source` line for detect-backend.sh | US-2, US-3 |
| `scripts/spec-retro.sh` | Add `SCRIPT_DIR` + `source` line for detect-backend.sh | US-2, US-3 |

### Modified Files -- Documentation (version references)

| File | Change | Traceability |
|------|--------|-------------|
| `CLAUDE.md` | Update routing table + prose version references | US-5 |
| `docs/agents/index.md` | Replace version references with tiers | US-5 |
| `docs/agents/spec-planner.md` | Replace version references | US-5 |
| `docs/agents/spec-reviewer.md` | Replace version references | US-5 |
| `docs/commands/index.md` | Replace version references | US-5 |
| `docs/commands/spec.md` | Replace version references | US-5 |
| `docs/workflow/overview.md` | Replace version references | US-5 |
| `docs/workflow/design.md` | Replace version references | US-5 |
| `docs/workflow/execution.md` | Replace version references | US-5 |
| `docs/workflow/tasks.md` | Replace version references | US-5 |
| `docs/workflow/requirements.md` | Replace version references | US-5 |
| `docs/getting-started/concepts.md` | Replace version references | US-5 |
| `docs/getting-started/quick-start.md` | Replace version references | US-5 |
| `docs/advanced/extending.md` | Replace version references | US-5 |

### Modified Files -- Version Bump

| File | Change | Traceability |
|------|--------|-------------|
| `.claude-plugin/plugin.json` | `"version": "5.1.0"` | US-6 |
| `skills/spec-workflow/SKILL.md` | `version: 5.1.0` | US-6 |

### Files NOT Modified

| File | Reason |
|------|--------|
| `.claude/specs/spec-intelligence-layer/*` | Archived spec (out of scope) |
| `.claude/specs/spec-plugin-v3-enhancements/*` | Archived spec (out of scope) |
| `commands/spec-team.sync-conflict-*.md` | Orphaned file (out of scope) |
| `commands/spec-validate.md` | Does not spawn agents via Task tool |
| `scripts/lib/checkpoint.sh` | Not affected |
| `scripts/lib/deps.sh` | Not affected |
| `scripts/lib/verify.sh` | Not affected |

---

## Implementation Considerations

### Security Considerations

- **No credential exposure**: The banner prints the value of `ANTHROPIC_BASE_URL`, which is a URL (not a secret). If users store secrets in this URL (e.g., API keys in query params), that is their responsibility. The URL is printed to stderr, not logged or persisted.
- **Env-var override is user-controlled**: The `SPEC_MODEL_*` vars are set by the user in their shell environment. No new attack surface is introduced -- the user already controls which model Claude Code uses.
- **No network calls**: Backend detection is purely string-based. No data leaves the machine during detection.

### Performance Considerations

- **Zero overhead for direct Anthropic users**: The detection check is a single string comparison (`case` statement). If `ANTHROPIC_BASE_URL` is unset, the function returns immediately. No measurable performance impact.
- **One-time banner**: The guard variable `_SPEC_BACKEND_NOTICE_SHOWN` prevents repeated printing. The `cat >&2` to print the banner is a single write syscall.

### Failure Modes and Recovery

- **Invalid env var value**: If `SPEC_MODEL_*` is set to a model that doesn't exist on the backend, the Task tool invocation will fail with a model resolution error. This is the same failure mode as if the user typed the wrong model name anywhere else. No special handling needed.
- **Missing `detect-backend.sh`**: If the helper file is missing, `source` will fail and `set -e` will terminate the script with a clear error. This is the existing behavior for missing library files (same as if `deps.sh` were missing).
- **`ANTHROPIC_BASE_URL` edge cases**: Empty string (set but empty) is treated the same as unset by the `-z` check -- the `case` statement is never reached. This correctly classifies an empty URL as "Anthropic backend" (no notice shown).

### Rollout Considerations

- **Frontmatter change is immediate**: Once the agent files are updated, all users get tier aliases. Users on direct Anthropic will see no behavioral difference (Claude Code resolves `opus` to the latest opus model).
- **Users who want specific pinning**: If a user previously relied on `claude-opus-4-6` being pinned (unlikely but possible), they can restore pinning via `SPEC_MODEL_PLANNER=claude-opus-4-6`. This is documented in `docs/advanced/model-routing.md`.
- **No migration needed**: The change is backward compatible. No user action is required for direct Anthropic users.

---

## Testing Strategy

This is a plugin composed of markdown files and shell scripts. Testing is manual.

### Test Plan 1: Direct Anthropic Path (Backward Compatibility)

**Preconditions**: `ANTHROPIC_BASE_URL` unset. No `SPEC_MODEL_*` vars set.

1. Run `/spec test-feature`. Verify:
   - spec-scanner, spec-planner, spec-tasker, spec-validator all spawn correctly
   - No optimization banner appears
   - Agents use expected models (opus for planner, sonnet for tasker, etc.)
2. Run `spec-exec.sh`. Verify:
   - No optimization banner on stderr
   - Script runs normally
3. Run `spec-loop.sh --max-iterations 1`. Verify:
   - No optimization banner on stderr
   - Script runs normally

### Test Plan 2: Non-Anthropic Backend Path

**Preconditions**: `ANTHROPIC_BASE_URL=http://localhost:4000`. No `SPEC_MODEL_*` vars set. `SPEC_QUIET` unset.

1. Run `spec-exec.sh`. Verify:
   - Optimization banner prints to stderr (redirect: `./spec-exec.sh 2>banner.txt` then check `banner.txt`)
   - Banner contains: header line, URL, all 11 env var names, example, doc pointer, suppress instruction
   - stdout output is not contaminated with banner content
2. Run `spec-exec.sh` a second time. Verify:
   - Banner prints again (once per invocation, not once per session)

### Test Plan 3: SPEC_QUIET Suppression

**Preconditions**: `ANTHROPIC_BASE_URL=http://localhost:4000`. `SPEC_QUIET=1`.

1. Run `spec-exec.sh 2>banner.txt`. Verify:
   - `banner.txt` is empty (no banner printed)

### Test Plan 4: Env-Var Override

**Preconditions**: `SPEC_MODEL_PLANNER=my-custom-model`.

1. Run `/spec test-override`. Observe the Task tool invocation for spec-planner.
2. Verify the Task tool receives `model: my-custom-model` (visible in Claude Code's debug output or by adding a log statement to the command prompt).

### Test Plan 5: Documentation Audit

1. Run: `grep -rn 'Opus 4\.6\|Sonnet 4\.6\|Haiku 4\.5\|claude-opus-4-6\|claude-sonnet-4-6\|claude-haiku-4-5' --include='*.md' . | grep -v '.claude/specs/spec-'`
2. Verify: zero matches (all version-pinned references removed from non-archived files)

### Test Plan 6: Version Bump

1. Read `.claude-plugin/plugin.json`. Verify `"version": "5.1.0"`.
2. Read `skills/spec-workflow/SKILL.md`. Verify `version: 5.1.0`.

---

## Alternatives Considered

### Alternative 1: Config File Instead of Env Vars

**Description**: Use a `.spec-driven.yml` or `.spec-driven.json` config file in the project root to define model mappings.

**Pros**:
- Persistent configuration without shell profile edits
- Could support per-project overrides

**Cons**:
- Adds a new file format to parse (shell scripts would need `yq` or `jq` dependency)
- Increases complexity for a niche use case
- Env vars are the established convention in the Claude Code ecosystem
- Violates the minimal engineering approach

**Decision**: Not chosen. Env vars are simpler, require no parsing dependencies, and align with how Claude Code itself is configured (via `ANTHROPIC_BASE_URL`, `ANTHROPIC_API_KEY`, etc.).

### Alternative 2: Model Mapping in plugin.json

**Description**: Add a `modelOverrides` section to `plugin.json` that maps agent names to model IDs.

**Pros**:
- Centralized, version-controlled configuration
- No env-var ceremony

**Cons**:
- `plugin.json` is the plugin author's file, not the user's. Users would need to fork the plugin to customize.
- Does not solve the per-user/per-environment customization need.
- Plugin.json schema is defined by Claude Code, not by this plugin.

**Decision**: Not chosen. The override mechanism should be user-controlled, not author-controlled. Env vars meet this requirement.

### Alternative 3: Auto-Detect Router Type

**Description**: Detect whether the backend is LiteLLM, CCR, or opencode and automatically suggest model mappings.

**Pros**:
- More helpful guidance for users
- Could auto-configure in some cases

**Cons**:
- Requires network calls or complex URL pattern matching
- Router detection is fragile (URLs are user-configurable)
- Violates NFR-3 (no network calls for detection)
- Over-engineering for the current use case

**Decision**: Not chosen. The notice is generic and points to documentation. Users can figure out their router's model names from their own router docs.
