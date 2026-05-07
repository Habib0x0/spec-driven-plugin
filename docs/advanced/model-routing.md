# Model Routing

The spec-driven plugin routes each agent to a **capability tier** rather than a specific model or vendor. Three tiers cover the range of work agents do:

| Tier | Capability | Used for |
|------|-----------|----------|
| `reasoning` | Deep reasoning, design, complex analysis | Requirements, architecture, code review — where subtle mistakes are most expensive |
| `standard` | Structured code production, validation, documentation | Implementation, task breakdown, testing — fast and accurate for well-specified work |
| `lightweight` | Targeted fixes, small patches | Debug patches where the failure is already identified — throughput matters more than depth |

Each agent declares its default tier in frontmatter. The CLI you are using resolves that tier to an actual model. If your CLI does not support tier aliases, or if you want to use a specific model, set the matching `SPEC_MODEL_*` environment variable.

## Tier Assignments

| Agent | Default Tier |
|-------|--------------|
| spec-planner | reasoning |
| spec-reviewer | reasoning |
| spec-tasker | standard |
| spec-validator | standard |
| spec-implementer | standard |
| spec-tester | standard |
| spec-acceptor | standard |
| spec-consultant | standard |
| spec-documenter | standard |
| spec-scanner | standard |
| spec-debugger | lightweight |

## How Tier Resolution Works

Each agent file (`agents/*.md`) declares its tier in YAML frontmatter:

```yaml
---
name: spec-planner
model: reasoning
---
```

The value in `model:` is a **tier alias**. How it gets resolved depends on your CLI:

- **Claude Code** — resolves `reasoning` → `opus`, `standard` → `sonnet`, `lightweight` → `haiku` automatically.
- **Codex** — does not use tier aliases; set `SPEC_MODEL_*` environment variables to point each agent at the model you want.
- **Custom CLI** (via `SPEC_AGENT_CMD`) — the plugin passes prompts to your command; model selection is up to your command.

No version strings are hardcoded in the plugin. Upgrading your CLI to a new model release picks up the new model automatically as long as the tier alias resolution is updated by the CLI.

## Per-Agent Override Variables

Every agent can be pinned to a specific model by setting its environment variable. This is the primary mechanism for routing to non-default models, non-Anthropic providers, or local routers.

| Variable | Agent | Default Tier |
|----------|-------|--------------|
| `SPEC_MODEL_PLANNER` | spec-planner | reasoning |
| `SPEC_MODEL_TASKER` | spec-tasker | standard |
| `SPEC_MODEL_VALIDATOR` | spec-validator | standard |
| `SPEC_MODEL_IMPLEMENTER` | spec-implementer | standard |
| `SPEC_MODEL_TESTER` | spec-tester | standard |
| `SPEC_MODEL_REVIEWER` | spec-reviewer | reasoning |
| `SPEC_MODEL_DEBUGGER` | spec-debugger | lightweight |
| `SPEC_MODEL_SCANNER` | spec-scanner | standard |
| `SPEC_MODEL_ACCEPTOR` | spec-acceptor | standard |
| `SPEC_MODEL_DOCUMENTER` | spec-documenter | standard |
| `SPEC_MODEL_CONSULTANT` | spec-consultant | standard |

### Precedence

```
SPEC_MODEL_* env var (if set and non-empty)
  |
  v  overrides
Agent frontmatter model: field (tier alias)
  |
  v  resolved by your CLI runtime
Actual model used for the agent
```

Setting a variable to an empty string is treated as unset — the frontmatter tier alias applies.

## CLI Detection

The plugin auto-detects which CLI is available:

1. If `SPEC_AGENT_CMD` is set, use that custom command.
2. If `codex` is installed, use Codex.
3. If `claude` is installed, use Claude Code.
4. Otherwise, error with instructions to install a supported CLI or set `SPEC_AGENT_CMD`.

Control this explicitly with `SPEC_AGENT_BACKEND`:

```bash
export SPEC_AGENT_BACKEND=claude   # force Claude Code
export SPEC_AGENT_BACKEND=codex    # force Codex
export SPEC_AGENT_BACKEND=auto     # default: auto-detect
```

## Mapping Tiers to Models by Provider

Set `SPEC_MODEL_*` variables to route each tier to a model your provider supports. The plugin passes the value through to the CLI without interpretation — any model string your CLI accepts works.

### Anthropic (Claude Code)

No configuration needed for defaults. To pin specific snapshots:

```bash
export SPEC_MODEL_PLANNER=claude-opus-4-7
export SPEC_MODEL_TASKER=claude-sonnet-4-6
export SPEC_MODEL_DEBUGGER=claude-haiku-4-5-20251001
```

### OpenAI

```bash
export SPEC_MODEL_PLANNER=o1
export SPEC_MODEL_REVIEWER=o1
export SPEC_MODEL_TASKER=gpt-4o
export SPEC_MODEL_IMPLEMENTER=gpt-4o
export SPEC_MODEL_TESTER=gpt-4o
export SPEC_MODEL_VALIDATOR=gpt-4o
export SPEC_MODEL_ACCEPTOR=gpt-4o
export SPEC_MODEL_CONSULTANT=gpt-4o
export SPEC_MODEL_DOCUMENTER=gpt-4o
export SPEC_MODEL_SCANNER=gpt-4o
export SPEC_MODEL_DEBUGGER=gpt-4o-mini
```

### Google (Gemini)

```bash
export SPEC_MODEL_PLANNER=gemini-1.5-pro
export SPEC_MODEL_REVIEWER=gemini-1.5-pro
export SPEC_MODEL_TASKER=gemini-1.5-pro
export SPEC_MODEL_IMPLEMENTER=gemini-1.5-pro
export SPEC_MODEL_DEBUGGER=gemini-1.5-flash
```

### DeepSeek

```bash
export SPEC_MODEL_PLANNER=deepseek-reasoner
export SPEC_MODEL_REVIEWER=deepseek-reasoner
export SPEC_MODEL_TASKER=deepseek-chat
export SPEC_MODEL_IMPLEMENTER=deepseek-chat
export SPEC_MODEL_DEBUGGER=deepseek-chat
```

### Local / Router (Ollama, CCR, LiteLLM, opencode)

```bash
# Example: Ollama with Qwen3
export SPEC_MODEL_PLANNER=qwen3-30b-a3b
export SPEC_MODEL_REVIEWER=qwen3-30b-a3b
export SPEC_MODEL_TASKER=qwen3-coder
export SPEC_MODEL_IMPLEMENTER=qwen3-coder
export SPEC_MODEL_DEBUGGER=qwen3-coder-7b

# Example: routed through LiteLLM
export SPEC_MODEL_PLANNER=deepseek-v3
export SPEC_MODEL_TASKER=qwen3-coder
export SPEC_MODEL_DEBUGGER=qwen3-coder-7b
```

## Suppressing Notices

Set `SPEC_QUIET=1` to suppress informational banners:

```bash
export SPEC_QUIET=1
```

## Version Pinning

If you need to lock an agent to a specific snapshot (for reproducibility, benchmarking, or to work around a regression), set the matching env var to the snapshot ID:

```bash
# Pin the planner to a specific snapshot
export SPEC_MODEL_PLANNER=claude-opus-4-7

# Or pin to a specific OSS model
export SPEC_MODEL_TASKER=qwen3-coder-2025-03-15
```

This works on any backend — the plugin does not interpret the value, it passes the string through to the CLI.
