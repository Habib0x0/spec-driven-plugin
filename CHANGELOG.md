# Changelog

All notable changes to the spec-driven plugin are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/) and this project adheres to [Semantic Versioning](https://semver.org/).

## [5.2.0] - 2026-04-29

### Fixed

- **`mapfile` incompatibility on macOS.** Replaced `mapfile -t` with POSIX-compatible `while IFS= read -r` loops in all 8 execution scripts. `mapfile` requires bash 4+; macOS ships bash 3.2, which caused all scripts to fail immediately with `bash: mapfile: command not found`.
- **`spec-scanner` and `spec-debugger` not registered in `plugin.json`.** Both agent files existed but were missing from the `agents` array, causing `/spec` Phase 0 to silently invoke the wrong agent.
- **`verify.sh` awk range pattern.** Fixed `awk '/^## Registration Points/,/^## /'` to exclude the closing heading line, which was bleeding content from the next section into the Registration Points data passed to the verification agent.
- **`verify.sh` git diff fallback on first commit.** Changed fallback from `git diff --cached` (returns empty after a commit) to `git diff --root HEAD`, which works correctly when there is only one commit in the repo.
- **`spec-loop.sh` task completion detection.** Replaced brittle `grep -B2` (failed when extra lines existed between `### T-N:` and the Status field) with an `awk` pattern that reliably extracts task IDs regardless of line spacing.
- **`spec-loop.sh` `comm -13` on empty strings.** Fixed false positives by writing snapshots to temp files before diffing, instead of piping `echo ""` (a single blank line) into `comm`.
- **`spec-complete.sh` no early exit after UAT failure.** Added explicit exit after setting `PIPELINE_STATUS=rejected/failed` to avoid printing confusing skip messages for subsequent pipeline steps.
- **Duplicate `detect-backend.sh` source.** Removed second `source` call in `spec-loop.sh` and `spec-exec.sh` (each sourced the file at startup and again in the library block).
- **`spec-root.sh` preference order.** Changed default spec root from `.codex/specs` to `.claude/specs` to match the Claude Code plugin's primary use case. `.codex/specs` is still detected and used as a migration fallback when present.

### Removed

- **`EnterPlanMode` reference** from `research.md` (tool does not exist in Claude Code).
- **`/spec-team` references** from `spec-accept.md` and `spec-status.md` (command was never implemented).
- **`/spec-debug` command references** from `spec-debugger.md` standalone mode section (command was never implemented; the workflow itself is preserved).

### Documentation

- Rewrote `README.md` to remove git worktree claims, `--no-worktree` flag, references to non-existent files (`REPORT_ENHANCEMENTS.md`, `ADVANCED_PATTERNS.md`, `HEADLESS_ORCHESTRATION.md`), and the incorrect marketplace path.
- Rewrote `docs/workflow/execution.md` to remove Mode 3 (spec-team), worktree section, and `/spec-sync` post-loop step.
- Rewrote `docs/advanced/worktrees.md` to accurately state worktree isolation is not implemented and document the recommended manual branch workflow.
- Updated `docs/commands/index.md`: removed `/spec-import`, `/spec-sync`, `/spec-team`; added `/spec-complete`, `/research`, `/zoom-out`, `/ubiquitous-language`; fixed script table.
- Deleted phantom command docs: `docs/commands/spec-team.md`, `docs/commands/spec-import.md`, `docs/commands/spec-sync.md`.
- Added `spec-scanner` agent role description to `docs/agents/index.md`.
- Added `spec-verify.sh` and `spec-complete.sh` promise markers to `docs/advanced/ci-cd.md`.
- Fixed `CLAUDE.md` to remove `--no-complete` flag claim and auto-chaining claim; replaced with accurate `--on-complete` opt-in description.
- Updated `skills/spec-workflow/SKILL.md` to version 5.2.0.
- Synced `.codex-plugin/plugin.json` to version 5.2.0.

## [5.1.1] - 2026-04-26

### Fixed

- **`spec-scanner` and `spec-debugger` agents** added to the model routing tables in `CLAUDE.md` and `docs/agents/index.md`. Both agents existed and were functional but were omitted from the public-facing documentation tables.
- **Commands table in `CLAUDE.md`** corrected to include `/research`, `/zoom-out`, and `/ubiquitous-language`, which were added in 5.1.0 but not reflected in the table.

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
