# Model Routing

The spec-driven plugin routes each agent to a **model tier** rather than a specific version-pinned model snapshot. Tier aliases (`opus`, `sonnet`, `haiku`) are resolved by Claude Code at runtime, so the plugin stays compatible with new model releases without plugin-side changes. Each agent's tier can be overridden per-environment via `SPEC_MODEL_*` environment variables, which is the mechanism that also lets you map tiers to non-Anthropic models when you route through Claude Code Router (CCR), LiteLLM, opencode, or similar routers.

## The Three-Tier System

The plugin uses three tiers matched to the work each agent does.

| Tier | Used for | Why |
|------|----------|-----|
| `opus` | Deep reasoning and design-sensitive review | Requirements, design, and code review are where subtle mistakes are most expensive — it's worth the token cost to catch them |
| `sonnet` | Structured code production | Implementation, task breakdown, validation, testing, documentation — fast, accurate, and good enough for well-specified work |
| `haiku` | Targeted lightweight fixes | Small debug patches where the failure is already identified — throughput matters more than depth |

### Tier Assignments

| Agent | Default Tier |
|-------|--------------|
| spec-planner | opus |
| spec-reviewer | opus |
| spec-tasker | sonnet |
| spec-validator | sonnet |
| spec-implementer | sonnet |
| spec-tester | sonnet |
| spec-acceptor | sonnet |
| spec-consultant | sonnet |
| spec-documenter | sonnet |
| spec-scanner | sonnet |
| spec-debugger | haiku |

## How Tier Resolution Works

Each agent file (`agents/*.md`) declares its tier in YAML frontmatter:

```yaml
---
name: spec-planner
model: opus
---
```

When a command spawns the agent through the Task tool, Claude Code resolves the tier alias to the current model in that tier at invocation time. No version strings are hardcoded in the plugin, so upgrading Claude Code to a new model release picks up the new model automatically — no plugin update required.

## Per-Agent Override Variables

Every agent's tier can be overridden by setting the matching environment variable. The plugin reads these variables in command prompts and passes them as the `model:` parameter to the Task tool when set and non-empty.

| Variable | Agent | Default Tier |
|----------|-------|--------------|
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
  v  overrides
Agent frontmatter model: field (tier alias)
  |
  v  resolved by Claude Code runtime
Actual model used for the agent
```

Setting a variable to an empty string is treated as unset — the frontmatter tier alias applies.

## Backend Detection

When `ANTHROPIC_BASE_URL` points at a non-Anthropic endpoint, shell scripts (`spec-exec.sh`, `spec-loop.sh`, etc.) print a one-time optimization notice suggesting which `SPEC_MODEL_*` variables to set for your router.

The detection is a pure string check on `ANTHROPIC_BASE_URL` — **no network calls** are made:

- Unset → treated as Anthropic (no banner).
- Contains `anthropic.com` → treated as Anthropic (no banner).
- Anything else → treated as non-Anthropic, banner prints once to stderr.

### Suppressing the Notice

Set `SPEC_QUIET=1` to suppress the banner. The banner is informational only; it never blocks execution.

```bash
export SPEC_QUIET=1
```

The banner also guards against repeat printing within a single process (using the `_SPEC_BACKEND_NOTICE_SHOWN` variable), so sourcing `detect-backend.sh` multiple times in the same script does not spam stderr.

## Router Configuration Examples

The examples below use hypothetical OSS models. Substitute whichever models your router actually exposes.

### Claude Code Router (CCR)

```bash
# Route through a local CCR instance
export ANTHROPIC_BASE_URL=http://localhost:3456/v1

# Map plugin tiers to your CCR-backed models
export SPEC_MODEL_PLANNER=deepseek-v3
export SPEC_MODEL_REVIEWER=deepseek-v3
export SPEC_MODEL_TASKER=qwen3-coder
export SPEC_MODEL_IMPLEMENTER=qwen3-coder
export SPEC_MODEL_TESTER=qwen3-coder
export SPEC_MODEL_VALIDATOR=qwen3-coder
export SPEC_MODEL_ACCEPTOR=qwen3-coder
export SPEC_MODEL_CONSULTANT=qwen3-coder
export SPEC_MODEL_DOCUMENTER=qwen3-coder
export SPEC_MODEL_SCANNER=qwen3-coder
export SPEC_MODEL_DEBUGGER=qwen3-coder-7b
```

### LiteLLM

```bash
# Point at your LiteLLM proxy
export ANTHROPIC_BASE_URL=http://litellm.local:4000

# LiteLLM lets you alias backend models; reuse those aliases in the env vars
export SPEC_MODEL_PLANNER=deepseek-v3
export SPEC_MODEL_REVIEWER=deepseek-v3
export SPEC_MODEL_TASKER=qwen3-coder
export SPEC_MODEL_IMPLEMENTER=qwen3-coder
export SPEC_MODEL_DEBUGGER=qwen3-coder-7b
```

### opencode

```bash
# opencode can route to any backend; set the base URL appropriately
export ANTHROPIC_BASE_URL=https://opencode.example.com/v1

export SPEC_MODEL_PLANNER=deepseek-v3
export SPEC_MODEL_TASKER=qwen3-coder
export SPEC_MODEL_DEBUGGER=qwen3-coder-7b
```

Any router that implements the Messages API and honors the `model` parameter works the same way — set `ANTHROPIC_BASE_URL` at the router, then use `SPEC_MODEL_*` to tell each agent which backend model to use.

## Restoring Version Pinning

If you need to lock an agent to a specific snapshot (for reproducibility, benchmarking, or to work around a regression), set the matching env var to the snapshot ID. The env var overrides the tier alias:

```bash
# Pin the planner to a specific Anthropic snapshot
export SPEC_MODEL_PLANNER=claude-opus-4-7

# Or pin to a specific OSS model
export SPEC_MODEL_TASKER=qwen3-coder-2025-03-15
```

This works on both Anthropic and non-Anthropic backends — the plugin does not interpret the value, it passes the string through to the Task tool's `model:` parameter.
