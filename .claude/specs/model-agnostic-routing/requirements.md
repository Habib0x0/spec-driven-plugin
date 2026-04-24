# Requirements: Model-Agnostic Routing

## Overview

Make the spec-driven plugin work correctly on any Claude-compatible backend (direct Anthropic API, Claude Code Router, LiteLLM, opencode, etc.) by removing snapshot-pinned model IDs from agent frontmatter, supporting tier aliases with env-var overrides, and showing a one-time optimization notice when a non-Anthropic backend is detected.

## User Roles

| Role | Description |
|------|-------------|
| Plugin User (Direct) | Developer using the plugin with the standard Anthropic API |
| Plugin User (Router) | Developer using the plugin through a third-party router or proxy (LiteLLM, CCR, opencode, etc.) |
| Plugin Author | Maintainer of the spec-driven plugin who needs to update model references on new Anthropic releases |

## User Stories

### US-1: Forward-Compatible Model References

**As a** Plugin Author
**I want** agent model references to use tier aliases instead of snapshot-pinned IDs
**So that** the plugin works on current and future Anthropic model generations without manual patching each release

#### Acceptance Criteria (EARS)

1. WHEN the plugin is loaded by Claude Code
   THE SYSTEM SHALL resolve agent models from tier alias strings (`opus`, `sonnet`, `haiku`) in the `model:` field of each agent's YAML frontmatter, not from snapshot-pinned identifiers like `claude-opus-4-6` or `claude-haiku-4-5-20251001`

   WARNING: `agents/spec-implementer.md` was involved in BUG-1: Anti-stub sweep. Ensure anti-stub enforcement text in the agent's system prompt body remains intact after editing the frontmatter.

   WARNING: `agents/spec-tester.md` was involved in BUG-1: Anti-stub sweep. Ensure anti-stub enforcement text in the agent's system prompt body remains intact after editing the frontmatter.

   WARNING: `agents/spec-reviewer.md` was involved in BUG-1: Anti-stub sweep. Ensure anti-stub enforcement text in the agent's system prompt body remains intact after editing the frontmatter.

2. WHEN any of the 11 agent files in `agents/*.md` is inspected
   THE SYSTEM SHALL contain exactly one of the following values in the `model:` YAML frontmatter field: `opus`, `sonnet`, or `haiku` -- with no version number, snapshot suffix, or `claude-` prefix

3. WHEN the plugin is used on a newer Anthropic model generation (e.g., Opus 4.7, Sonnet 5.0)
   THE SYSTEM SHALL route agents to the correct model tier without any file edits, because the frontmatter contains only the tier alias

4. THE SYSTEM SHALL preserve the existing tier assignments: `spec-planner` and `spec-reviewer` on `opus`; `spec-tasker`, `spec-validator`, `spec-implementer`, `spec-tester`, `spec-acceptor`, `spec-consultant`, `spec-documenter`, and `spec-scanner` on `sonnet`; `spec-debugger` on `haiku`

---

### US-2: Non-Anthropic Backend Compatibility

**As a** Plugin User (Router)
**I want** the plugin to work when I run Claude Code against a non-Anthropic backend
**So that** I can use the spec-driven workflow with any Claude-compatible router or proxy

#### Acceptance Criteria (EARS)

1. WHEN a user runs a shell script (`spec-exec.sh`, `spec-loop.sh`, `spec-complete.sh`, `spec-accept.sh`, `spec-docs.sh`, `spec-release.sh`, `spec-verify.sh`, `spec-retro.sh`) and the environment variable `ANTHROPIC_BASE_URL` is unset
   THE SYSTEM SHALL treat the backend as Anthropic (direct API) and not display any optimization notice

2. WHEN a user runs a shell script and `ANTHROPIC_BASE_URL` is set to a value containing the substring `anthropic.com` (e.g., `https://api.anthropic.com/v1`)
   THE SYSTEM SHALL treat the backend as Anthropic and not display any optimization notice

3. WHEN a user runs a shell script and `ANTHROPIC_BASE_URL` is set to a value that does NOT contain the substring `anthropic.com` (e.g., `http://localhost:4000`, `https://my-litellm.example.com/v1`)
   THE SYSTEM SHALL treat the backend as non-Anthropic and display the optimization notice (subject to `SPEC_QUIET` suppression per US-3)

4. THE SYSTEM SHALL NOT make any network calls, DNS lookups, or HTTP requests as part of backend detection -- detection is purely string-based on the `ANTHROPIC_BASE_URL` environment variable

5. WHEN the plugin runs on direct Anthropic API (no `ANTHROPIC_BASE_URL` set, or set to an `anthropic.com` URL)
   THE SYSTEM SHALL behave identically to v5.0.3 in all functional aspects (backward compatibility)

   WARNING: `scripts/spec-exec.sh` was involved in BUG-1: Anti-stub sweep. Ensure anti-stub enforcement text in the prompt template remains intact after adding backend detection sourcing.

   WARNING: `scripts/spec-loop.sh` was involved in BUG-1: Anti-stub sweep. Ensure anti-stub enforcement text in the prompt template remains intact after adding backend detection sourcing.

---

### US-3: Non-Anthropic Backend Guidance Notice

**As a** Plugin User (Router)
**I want** to receive guidance about optimizing model routing when I'm on a non-Anthropic backend
**So that** I know which env vars to set and where to find configuration documentation

#### Acceptance Criteria (EARS)

1. WHEN a non-Anthropic backend is detected (per US-2 AC-3) and `SPEC_QUIET` is not set to `1`
   THE SYSTEM SHALL print an optimization notice to stderr containing ALL of the following:
   - A header line: `[spec-driven] Non-Anthropic backend detected`
   - The detected URL (value of `ANTHROPIC_BASE_URL`)
   - The complete list of 11 per-agent env var names: `SPEC_MODEL_PLANNER`, `SPEC_MODEL_IMPLEMENTER`, `SPEC_MODEL_DEBUGGER`, `SPEC_MODEL_TASKER`, `SPEC_MODEL_VALIDATOR`, `SPEC_MODEL_REVIEWER`, `SPEC_MODEL_TESTER`, `SPEC_MODEL_SCANNER`, `SPEC_MODEL_ACCEPTOR`, `SPEC_MODEL_DOCUMENTER`, `SPEC_MODEL_CONSULTANT`
   - A placeholder example for at least one env var (e.g., `export SPEC_MODEL_PLANNER=deepseek-v3`)
   - A pointer to the documentation file: `docs/advanced/model-routing.md`
   - Instructions to suppress the notice: `export SPEC_QUIET=1`

2. THE SYSTEM SHALL print the optimization notice to stderr (file descriptor 2), not stdout (file descriptor 1), so that it does not pollute output that tooling may parse

3. THE SYSTEM SHALL print the optimization notice at most once per script invocation, even if multiple functions or code paths re-source the detection helper

4. WHEN `SPEC_QUIET` is set to `1`
   THE SYSTEM SHALL NOT print the optimization notice, regardless of backend detection result

5. WHEN `SPEC_QUIET` is set to any value other than `1` (e.g., `0`, `true`, empty string) or is unset
   THE SYSTEM SHALL NOT suppress the notice (only the exact value `1` suppresses)

---

### US-4: Per-Agent Model Override via Environment Variables

**As a** Plugin User (Router)
**I want** to override the model used for each agent via environment variables
**So that** I can map each agent tier to the specific model my router exposes

#### Acceptance Criteria (EARS)

1. WHEN the `/spec` command spawns the `spec-planner` agent via the Task tool and the environment variable `SPEC_MODEL_PLANNER` is set to a non-empty string
   THE SYSTEM SHALL pass the value of `SPEC_MODEL_PLANNER` as the `model:` parameter to the Task tool invocation, overriding the frontmatter default

   WARNING: `commands/spec.md` was involved in BUG-2: Validate-fix loop routing. Ensure the validate-fix loop in Step 4.5 still routes vague-requirement issues to `spec-planner` and task-traceability issues to `spec-tasker` after adding env-var override instructions.

2. WHEN any `SPEC_MODEL_*` environment variable is set for a given agent
   THE SYSTEM SHALL use that value as the model identifier passed to the Task tool, regardless of what tier alias is in the agent's frontmatter

3. WHEN no `SPEC_MODEL_*` environment variable is set for a given agent
   THE SYSTEM SHALL use the tier alias from the agent's YAML frontmatter (e.g., `opus`, `sonnet`, `haiku`) as the model

4. THE SYSTEM SHALL support the following env-var-to-agent mapping (one variable per agent, all 11 covered):

   | Env Var | Agent | Default Tier |
   |---------|-------|-------------|
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

5. WHEN a command that spawns agents (at minimum: `commands/spec.md`, `commands/spec-brainstorm.md`, `commands/spec-refine.md`, `commands/spec-tasks.md`, `commands/spec-validate.md`) invokes the Task tool
   THE SYSTEM SHALL include instructions in the command prompt to check the relevant `SPEC_MODEL_*` env var and pass it as the `model:` parameter when set

6. THE SYSTEM SHALL NOT attempt env-var interpolation inside YAML frontmatter -- the override mechanism lives entirely in the spawning command's prompt logic

---

### US-5: Accurate Model-Agnostic Documentation

**As a** Plugin User (Direct or Router)
**I want** documentation to describe model routing in terms of tiers rather than pinned version numbers
**So that** the docs remain accurate regardless of which model generation or backend I'm using

#### Acceptance Criteria (EARS)

1. WHEN a user reads `CLAUDE.md`
   THE SYSTEM SHALL display a "Model Routing" table that uses tier names (`opus` / `sonnet` / `haiku`) and tier descriptions (e.g., "Deep reasoning for edge cases and architecture") instead of version-specific identifiers like "Opus 4.6" or "Sonnet 4.6"

2. WHEN a user reads `commands/spec.md`
   THE SYSTEM SHALL display a "Model Routing" table that uses tier names and descriptions without version-specific identifiers

3. WHEN a user reads any of the 11 agent files in `agents/*.md`
   THE SYSTEM SHALL find `description:` text that references tiers (e.g., "runs on the opus tier for deep reasoning") rather than specific versions (e.g., "runs on Opus 4.6")

4. WHEN a user reads documentation under `docs/agents/`, `docs/commands/index.md`, `docs/commands/spec.md`, `docs/workflow/`, `docs/getting-started/`, or `docs/advanced/extending.md`
   THE SYSTEM SHALL find tier-based language instead of version-pinned references for all model mentions

5. WHEN a user reads `docs/advanced/model-routing.md`
   THE SYSTEM SHALL find a guide containing ALL of:
   - Explanation of the three-tier system (opus/sonnet/haiku) and which agents use which tier
   - Full list of `SPEC_MODEL_*` env vars with descriptions
   - Explanation of override precedence (env var > frontmatter tier alias)
   - Description of backend detection behavior (`ANTHROPIC_BASE_URL` logic)
   - Instructions for suppressing the notice (`SPEC_QUIET=1`)
   - Example router configurations for at least three routers: Claude Code Router (CCR), LiteLLM, and opencode
   - Example model mappings using hypothetical OSS models (e.g., DeepSeek-V3 for opus tier, Qwen3-Coder for sonnet tier, a small 7B-8B model for haiku tier)

6. THE SYSTEM SHALL NOT modify any files under `.claude/specs/spec-intelligence-layer/` or `.claude/specs/spec-plugin-v3-enhancements/` (archived specs are out of scope)

---

### US-6: Version Bump

**As a** Plugin Author
**I want** the plugin version to be bumped from `5.0.3` to `5.1.0`
**So that** the model-agnostic routing change is identifiable as a minor (feature) release

#### Acceptance Criteria (EARS)

1. WHEN `.claude-plugin/plugin.json` is inspected
   THE SYSTEM SHALL show `"version": "5.1.0"`

2. WHEN `skills/spec-workflow/SKILL.md` is inspected
   THE SYSTEM SHALL show `version: 5.1.0` in the YAML frontmatter

---

## Non-Functional Requirements

### NFR-1: Banner Output Isolation

THE SYSTEM SHALL print the optimization notice exclusively to stderr (file descriptor 2). No banner content shall appear on stdout under any circumstances.

### NFR-2: Banner Idempotency

THE SYSTEM SHALL print the optimization notice at most once per shell script invocation. If `detect-backend.sh` is sourced multiple times within a single script (e.g., sourced by both the main script and a nested library), the notice shall only print on the first sourcing.

### NFR-3: No Network Calls for Detection

THE SYSTEM SHALL NOT make any network calls (HTTP requests, DNS lookups, TCP connections) as part of the backend detection logic. Detection is a pure string comparison on the `ANTHROPIC_BASE_URL` environment variable.

### NFR-4: Backward Compatibility

WHEN no `SPEC_MODEL_*` environment variables are set and `ANTHROPIC_BASE_URL` is unset or points to `anthropic.com`
THE SYSTEM SHALL behave identically to v5.0.3 for all functional workflows. The only difference is the tier alias string in frontmatter instead of the snapshot ID, which Claude Code resolves equivalently.

### NFR-5: Shell Script Convention Compliance

THE SYSTEM SHALL follow the existing `set -e` convention (PAT-3) in the new `scripts/lib/detect-backend.sh` helper. The helper shall NOT use `set -euo pipefail` or any convention that deviates from the existing scripts.

### NFR-6: Minimal File Scope

THE SYSTEM SHALL limit file modifications to the files enumerated in design.md. In particular, the following files shall NOT be modified:
- `.claude/specs/spec-intelligence-layer/*` (archived spec)
- `.claude/specs/spec-plugin-v3-enhancements/*` (archived spec)
- `commands/spec-team.sync-conflict-20260407-015530-WTRWCNZ.md` (orphaned file)

---

## Out of Scope

- Runtime model validation (checking if the model string actually resolves on the backend)
- Automatic model mapping (guessing which OSS model corresponds to which tier)
- Configuration files beyond env vars (no `.spec-driven.yml` or similar config file)
- Changes to the Task tool itself or Claude Code's model resolution internals
- Modifying shell scripts to pass `--model` flags (scripts inherit the session model; only the banner is new behavior for scripts)
- Auto-detection of router type (LiteLLM vs. CCR vs. opencode) -- the notice is generic
- Changes to archived spec files under `.claude/specs/`

## Assumptions

1. Claude Code's Task tool accepts `model:` as a parameter that overrides the agent's frontmatter `model:` field. This is confirmed by the existing `commands/spec.md` agent-spawning pattern.
2. Claude Code resolves tier alias strings (`opus`, `sonnet`, `haiku`) in agent frontmatter to the latest available model in that tier. This is the standard Claude Code plugin behavior.
3. The `ANTHROPIC_BASE_URL` environment variable is the standard way users configure non-Anthropic backends. Other variables (like `OPENAI_BASE_URL`) are not relevant to this plugin's detection.
4. Shell scripts inherit the session model from the `claude` CLI invocation and do not need to pass `--model` explicitly. The env-var override mechanism is only needed at the command/Task-tool level, not in scripts.

## Detected Gaps (Informational)

- `spec-scanner` agent: not registered in `plugin.json` or `CLAUDE.md` routing table (confidence: high)
- `spec-debugger` agent: not registered in `plugin.json` (confidence: high)
- `spec-complete` command: no docs page at `docs/commands/spec-complete.md` (confidence: high)
