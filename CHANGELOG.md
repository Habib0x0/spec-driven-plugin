# Changelog

All notable changes to the spec-driven plugin are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/) and this project adheres to [Semantic Versioning](https://semver.org/).

## [5.1.0] - 2026-04-23

### Changed

- **Model-agnostic routing.** All 11 agents now use tier aliases (`opus`, `sonnet`, `haiku`) in their `model:` frontmatter instead of version-pinned snapshots like `claude-opus-4-6`. Claude Code resolves each tier to the current model at runtime, so the plugin stays compatible with new Claude releases without plugin-side changes. This fixes inconsistent behavior on Opus 4.7 and later releases that was caused by pinning to 4.6 snapshots.
- **Documentation refactor.** `CLAUDE.md`, `docs/`, and all command prompts now describe agents by tier (e.g., "opus tier") rather than by version string. The routing tables in `CLAUDE.md` and `docs/agents/index.md` now include all 11 agents, including `spec-scanner`, which was previously missing from the public-facing tables.

### Added

- **Per-agent model overrides.** Each agent's tier can be overridden via a `SPEC_MODEL_*` environment variable (`SPEC_MODEL_PLANNER`, `SPEC_MODEL_TASKER`, `SPEC_MODEL_VALIDATOR`, `SPEC_MODEL_IMPLEMENTER`, `SPEC_MODEL_TESTER`, `SPEC_MODEL_REVIEWER`, `SPEC_MODEL_DEBUGGER`, `SPEC_MODEL_SCANNER`, `SPEC_MODEL_ACCEPTOR`, `SPEC_MODEL_DOCUMENTER`, `SPEC_MODEL_CONSULTANT`). When set and non-empty, the value is passed as the `model:` parameter to the Task tool, overriding the frontmatter alias. Useful for pinning a specific snapshot or mapping tiers to non-Anthropic models behind a router.
- **Non-Anthropic backend detection.** New `scripts/lib/detect-backend.sh` helper, sourced by all 8 execution scripts. Performs a pure string check on `ANTHROPIC_BASE_URL` with no network calls. When a non-Anthropic URL is detected, prints a one-time optimization notice to stderr listing the `SPEC_MODEL_*` variables and pointing at the new routing doc. Suppress with `SPEC_QUIET=1`.
- **`docs/advanced/model-routing.md`.** New comprehensive guide covering the three-tier system, tier resolution, per-agent overrides with precedence rules, backend detection behavior, router configuration examples (Claude Code Router, LiteLLM, opencode), and how to restore version pinning when reproducibility matters.
- **Env-var override instructions in 4 command prompts.** `commands/spec.md`, `spec-brainstorm.md`, `spec-refine.md`, and `spec-tasks.md` now instruct Claude to check the relevant `SPEC_MODEL_*` variable before spawning agents via the Task tool.

### Preserved

- Anti-stub enforcement text in `agents/spec-implementer.md`, `agents/spec-tester.md`, and `agents/spec-reviewer.md` is unchanged — only YAML frontmatter was edited in those three files.
- The `/spec` validate-fix loop in `commands/spec.md` still routes requirement/design issues to `spec-planner` and task-traceability issues to `spec-tasker` as two distinct conditions.
- Prompt template heredocs in `scripts/spec-exec.sh` and `scripts/spec-loop.sh` are unchanged — the new `detect-backend.sh` source call is in the script preamble, not inside the prompt.

### Migration

No action required for Anthropic backend users — the tier aliases resolve automatically to the current model, so upgrading is transparent.

Users on a non-Anthropic backend (CCR, LiteLLM, opencode, etc.) will see a one-time optimization notice on stderr suggesting which `SPEC_MODEL_*` variables to set. The notice is informational; scripts continue to work without setting anything. To suppress: `export SPEC_QUIET=1`.

To restore version pinning, set the relevant `SPEC_MODEL_*` variable to a specific snapshot ID (e.g., `SPEC_MODEL_PLANNER=claude-opus-4-7`).

## [5.0.3] - earlier

See git history for releases prior to 5.1.0.
