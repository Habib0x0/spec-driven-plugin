# Tasks: Model-Agnostic Routing

<!--
IMPORTANT: Do NOT edit task descriptions, acceptance criteria, or dependencies.
Only update Status, Wired, and Verified fields. This ensures traceability.

Status lifecycle: pending → in_progress → completed → (only after Wired + Verified)
Wired: Is this code connected to the rest of the application? Can a user reach it?
Verified: Has it been tested end-to-end as a user would interact with it?
-->

## Summary

| Phase | Tasks | Status |
|-------|-------|--------|
| Phase 1: Setup | 1 | completed |
| Phase 2: Core Implementation | 3 | completed |
| Phase 3: Integration | 3 | completed |
| Phase 4: Testing | 3 | completed |
| Phase 5: Polish | 2 | completed |
| **Total** | **12** | |

## Wiring Map

| Implementation Task | Integration Task | What Gets Connected |
|--------------------|-----------------|---------------------|
| T-2 (agent frontmatter) | T-6 (CLAUDE.md + routing tables) | Tier aliases verified in command routing tables |
| T-3 (command prompt overrides) | T-6 (commands/spec.md) | Model Override section present in spawning commands |
| T-1 (detect-backend.sh) | T-5 (shell script banner injection) | 8 scripts source the new detection helper |
| T-4 (docs + model-routing.md) | T-7 (version bump) | Version 5.1.0 marks the release |

---

## Phase 1: Setup

### T-1: Create backend detection shell helper

- **Status**: completed
- **Wired**: n/a
- **Verified**: yes
- **Requirements**: US-2, US-3, NFR-1, NFR-2, NFR-3, NFR-5
- **Description**: Create `scripts/lib/detect-backend.sh`. This new file provides two behaviors: (1) an `is_anthropic_backend()` function that returns 0 if `ANTHROPIC_BASE_URL` is unset or contains `anthropic.com`, returns 1 otherwise -- pure string check, no network calls; (2) an idempotency-guarded block at source time that calls `is_anthropic_backend()` and, if non-Anthropic and `SPEC_QUIET != 1`, prints the optimization notice to stderr exactly once per process using the guard variable `_SPEC_BACKEND_NOTICE_SHOWN`. The notice must include: header line `[spec-driven] Non-Anthropic backend detected`, the actual value of `ANTHROPIC_BASE_URL`, all 11 `SPEC_MODEL_*` var names (`SPEC_MODEL_PLANNER`, `SPEC_MODEL_IMPLEMENTER`, `SPEC_MODEL_DEBUGGER`, `SPEC_MODEL_TASKER`, `SPEC_MODEL_VALIDATOR`, `SPEC_MODEL_REVIEWER`, `SPEC_MODEL_TESTER`, `SPEC_MODEL_SCANNER`, `SPEC_MODEL_ACCEPTOR`, `SPEC_MODEL_DOCUMENTER`, `SPEC_MODEL_CONSULTANT`), an example (`export SPEC_MODEL_PLANNER=deepseek-v3`), pointer to `docs/advanced/model-routing.md`, and suppress instruction (`export SPEC_QUIET=1`). Follow existing `scripts/lib/` conventions: `#!/usr/bin/env bash` shebang, compatible with `set -e` parent context. Do NOT use `set -euo pipefail` (NFR-5). The `ANTHROPIC_BASE_URL` value must be interpolated at runtime in the notice -- not printed as a literal string.
- **Acceptance**:
  - `scripts/lib/detect-backend.sh` exists and is valid bash (`bash -n scripts/lib/detect-backend.sh` exits 0)
  - `is_anthropic_backend()` function is defined in the file
  - With `ANTHROPIC_BASE_URL` unset: `bash -c '. scripts/lib/detect-backend.sh; is_anthropic_backend && echo ok'` prints `ok`, no banner on stderr
  - With `ANTHROPIC_BASE_URL=https://api.anthropic.com/v1`: `is_anthropic_backend` returns 0, no banner
  - With `ANTHROPIC_BASE_URL=http://localhost:4000` and `SPEC_QUIET` unset: banner prints to stderr containing the strings `[spec-driven] Non-Anthropic backend detected`, `http://localhost:4000`, `SPEC_MODEL_PLANNER`, `SPEC_MODEL_DEBUGGER`, `docs/advanced/model-routing.md`, and `SPEC_QUIET=1`
  - With `ANTHROPIC_BASE_URL=http://localhost:4000` and `SPEC_QUIET=1`: no banner output on stderr
  - When sourced twice in the same process with a non-Anthropic URL: banner appears exactly once (guard variable `_SPEC_BACKEND_NOTICE_SHOWN` prevents repeat)
  - File does not contain `set -euo pipefail`
- **Dependencies**: none

---

## Phase 2: Core Implementation

### T-2: Refactor all 11 agent frontmatter files to use tier aliases

- **Status**: completed
- **Wired**: yes
- **Verified**: yes
- **Requirements**: US-1, US-5
- **Description**: Edit all 11 files in `agents/*.md`. For each file, change the `model:` frontmatter field from the snapshot-pinned ID to the tier alias: `agents/spec-planner.md` and `agents/spec-reviewer.md` -> `model: opus`; `agents/spec-tasker.md`, `agents/spec-validator.md`, `agents/spec-implementer.md`, `agents/spec-tester.md`, `agents/spec-acceptor.md`, `agents/spec-consultant.md`, `agents/spec-documenter.md`, `agents/spec-scanner.md` -> `model: sonnet`; `agents/spec-debugger.md` -> `model: haiku`. Also update `description:` frontmatter text in all files that reference version-specific names -- use tier language instead (e.g., "runs on the opus tier" not "runs on Opus 4.6"). For `agents/spec-planner.md` only, also update the system prompt body line that reads "You run on Opus for deep reasoning" to "You run on the opus tier for deep reasoning". REGRESSION GUARD (BUG-1): For `agents/spec-implementer.md`, `agents/spec-tester.md`, and `agents/spec-reviewer.md`, only edit the YAML frontmatter block (content between the opening `---` and closing `---` delimiters). Do NOT modify any text below the closing `---` delimiter in those three files -- the anti-stub enforcement text must remain intact.
- **Acceptance**:
  - `grep -n "^model:" agents/*.md` shows `model: opus` for spec-planner and spec-reviewer, `model: sonnet` for the 9 sonnet-tier agents, `model: haiku` for spec-debugger (11 lines total)
  - No agent file contains `claude-opus-4-6`, `claude-sonnet-4-6`, or `claude-haiku-4-5-20251001` anywhere in the file
  - `description:` fields in spec-planner, spec-tasker, spec-reviewer use tier language (e.g., "opus tier") and not version strings
  - The system prompt body of `agents/spec-implementer.md` below the closing `---` is unchanged from before this task (BUG-1)
  - The system prompt body of `agents/spec-tester.md` below the closing `---` is unchanged from before this task (BUG-1)
  - The system prompt body of `agents/spec-reviewer.md` below the closing `---` is unchanged from before this task (BUG-1)
- **Dependencies**: none

### T-3: Add env-var override instructions to 4 command prompts

- **Status**: completed
- **Wired**: yes
- **Verified**: yes
- **Requirements**: US-4, US-5
- **Description**: Edit `commands/spec.md`, `commands/spec-brainstorm.md`, `commands/spec-refine.md`, and `commands/spec-tasks.md`. For each, add a "Model Override" section (or equivalent inline instruction) directing the command to check the relevant `SPEC_MODEL_*` env var when spawning each agent via the Task tool, and pass it as the `model:` parameter when set and non-empty. Per-command changes: (a) `commands/spec.md` -- add override checks for `SPEC_MODEL_SCANNER`, `SPEC_MODEL_PLANNER`, `SPEC_MODEL_TASKER`, `SPEC_MODEL_VALIDATOR`. REGRESSION GUARD (BUG-2): The validate-fix loop in Step 4.5 that routes vague-requirement issues to `spec-planner` and task-traceability issues to `spec-tasker` must remain intact -- only add the model override parameter, do not alter the routing conditions or agent selection logic. (b) `commands/spec-brainstorm.md` -- add override check for `SPEC_MODEL_CONSULTANT`. (c) `commands/spec-refine.md` -- add override checks for `SPEC_MODEL_PLANNER` and `SPEC_MODEL_TASKER`. (d) `commands/spec-tasks.md` -- add override check for `SPEC_MODEL_TASKER`. Do NOT modify `commands/spec-validate.md` (it does not spawn agents via the Task tool).
- **Acceptance**:
  - `commands/spec.md` contains a "Model Override" section or equivalent instruction listing `SPEC_MODEL_SCANNER`, `SPEC_MODEL_PLANNER`, `SPEC_MODEL_TASKER`, `SPEC_MODEL_VALIDATOR` with directions to pass the value as `model:` to the Task tool when set
  - `commands/spec-brainstorm.md` contains an instruction to check `SPEC_MODEL_CONSULTANT` when spawning the consultant agent
  - `commands/spec-refine.md` contains instructions for `SPEC_MODEL_PLANNER` and `SPEC_MODEL_TASKER`
  - `commands/spec-tasks.md` contains an instruction for `SPEC_MODEL_TASKER`
  - `commands/spec.md` still contains a validate-fix conditional that routes to `spec-planner` for requirement/design issues and `spec-tasker` for task-traceability issues (two distinct routing paths, not collapsed into one) (BUG-2)
  - `commands/spec-validate.md` does not contain `SPEC_MODEL_` text (unmodified)
- **Dependencies**: none

### T-4: Refactor docs to use tier language and create model-routing.md

- **Status**: completed
- **Wired**: yes
- **Verified**: yes
- **Requirements**: US-5
- **Description**: Two parts. Part A -- Replace all version-pinned model references with tier language across these existing files: `CLAUDE.md`, `docs/agents/index.md`, `docs/agents/spec-planner.md`, `docs/agents/spec-reviewer.md`, `docs/commands/index.md`, `docs/commands/spec.md`, `docs/workflow/overview.md`, `docs/workflow/design.md`, `docs/workflow/execution.md`, `docs/workflow/tasks.md`, `docs/workflow/requirements.md`, `docs/getting-started/concepts.md`, `docs/getting-started/quick-start.md`, `docs/advanced/extending.md`. Replace patterns: `Opus 4.6` -> `opus tier`; `Sonnet 4.6` -> `sonnet tier`; `Haiku 4.5` -> `haiku tier`; `claude-opus-4-6` -> `opus`; `claude-sonnet-4-6` -> `sonnet`; `claude-haiku-4-5-20251001` -> `haiku`. In `CLAUDE.md` specifically: update the Model Routing table to use a "Model Tier" column (values `opus`/`sonnet`/`haiku`), and add a note: "Each agent's model can be overridden via environment variable (e.g., `SPEC_MODEL_PLANNER=my-model`). See `docs/advanced/model-routing.md` for details." Do not touch files under `.claude/specs/spec-intelligence-layer/` or `.claude/specs/spec-plugin-v3-enhancements/` (NFR-6). Part B -- Create `docs/advanced/model-routing.md` as a new comprehensive guide containing: (1) intro to three-tier system, (2) tier definitions with agent assignments (opus: spec-planner, spec-reviewer; sonnet: all others except debugger; haiku: spec-debugger), (3) how tier resolution works at runtime, (4) full table of all 11 `SPEC_MODEL_*` env vars with agent name and default tier, (5) override precedence (env var > frontmatter), (6) backend detection behavior (`ANTHROPIC_BASE_URL` string check, no network calls), (7) optimization notice explanation and `SPEC_QUIET=1` suppression, (8) router configuration examples for CCR, LiteLLM, and opencode using hypothetical OSS models (DeepSeek-V3 for opus tier, qwen3-coder for sonnet tier, a lightweight 7-8B model for haiku tier), (9) how to restore version pinning via env var.
- **Acceptance**:
  - `grep -rn 'Opus 4\.6\|Sonnet 4\.6\|Haiku 4\.5\|claude-opus-4-6\|claude-sonnet-4-6\|claude-haiku-4-5' --include='*.md' docs/ CLAUDE.md` returns zero matches
  - `CLAUDE.md` Model Routing table has a "Model Tier" (or equivalent) column with values `opus`, `sonnet`, `haiku` only -- no version suffixes
  - `CLAUDE.md` contains the text `SPEC_MODEL_PLANNER` and a link to `docs/advanced/model-routing.md`
  - `docs/advanced/model-routing.md` exists and contains all 11 `SPEC_MODEL_*` var names in a table
  - `docs/advanced/model-routing.md` contains configuration examples with the strings `CCR` or `Claude Code Router`, `LiteLLM`, and `opencode`
  - `docs/advanced/model-routing.md` contains the strings `SPEC_QUIET=1`, `ANTHROPIC_BASE_URL`, and `deepseek-v3`
  - Files under `.claude/specs/spec-intelligence-layer/` and `.claude/specs/spec-plugin-v3-enhancements/` have no changes (NFR-6)
- **Dependencies**: none

---

## Phase 3: Integration

### T-5: Inject detect-backend.sh source call into 8 shell scripts

- **Status**: completed
- **Wired**: yes
- **Verified**: yes
- **Requirements**: US-2, US-3
- **Description**: For each of the 8 shell scripts, wire in the backend detection helper by adding a `source` call. For scripts that already define `SCRIPT_DIR` and have existing `source` lines (`scripts/spec-exec.sh`, `scripts/spec-loop.sh`, `scripts/spec-complete.sh`): add `source "$SCRIPT_DIR/lib/detect-backend.sh"` immediately after the last existing `source` line. For scripts that do not yet define `SCRIPT_DIR` (`scripts/spec-accept.sh`, `scripts/spec-docs.sh`, `scripts/spec-release.sh`, `scripts/spec-verify.sh`, `scripts/spec-retro.sh`): check each script individually -- if `SCRIPT_DIR` is absent, add `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"` after `set -e`, then add the `source` line. REGRESSION GUARD (BUG-1): For `scripts/spec-exec.sh` and `scripts/spec-loop.sh`, the new `source` line goes in the preamble only. Do NOT touch the prompt template heredoc section in either script -- the anti-stub enforcement text in those heredocs must remain identical to the pre-edit content.
- **Acceptance**:
  - All 8 scripts contain `source "$SCRIPT_DIR/lib/detect-backend.sh"` (confirmed by grep)
  - `bash -n` on all 8 scripts exits 0 with no syntax errors
  - The prompt template heredoc content in `scripts/spec-exec.sh` is unchanged (BUG-1)
  - The prompt template heredoc content in `scripts/spec-loop.sh` is unchanged (BUG-1)
  - `grep -c 'detect-backend' scripts/spec-exec.sh scripts/spec-loop.sh scripts/spec-complete.sh scripts/spec-accept.sh scripts/spec-docs.sh scripts/spec-release.sh scripts/spec-verify.sh scripts/spec-retro.sh` shows exactly 1 match per file
- **Dependencies**: T-1

### T-6: Verify CLAUDE.md and commands/spec.md routing tables reflect tier aliases

- **Status**: completed
- **Wired**: n/a
- **Verified**: yes
- **Requirements**: US-5
- **Description**: This integration task ensures the two routing tables most visible to users are consistent with the tier-alias refactor completed in T-2, T-3, and T-4. Read `CLAUDE.md` and confirm: the Model Routing table uses only `opus`, `sonnet`, `haiku` values (no version strings); rows exist for all 11 agents including `spec-scanner` and `spec-debugger` (detected as missing from the routing table per requirements gap analysis); the env-var override note is present. Read `commands/spec.md` and confirm: the Model Routing table is version-free; the Model Override section lists all 4 relevant `SPEC_MODEL_*` vars. If any of these checks fail (meaning T-4 or T-3 left gaps), fill them now.
- **Acceptance**:
  - `CLAUDE.md` Model Routing table has exactly 11 rows (one per agent), all with tier values `opus`, `sonnet`, or `haiku` in the model column
  - `CLAUDE.md` routing table includes `spec-scanner` and `spec-debugger` rows
  - `commands/spec.md` Model Routing table contains no occurrence of `4.6`, `4.5`, or `claude-` prefixed strings
  - `grep 'SPEC_MODEL_' commands/spec.md` shows references to `SPEC_MODEL_SCANNER`, `SPEC_MODEL_PLANNER`, `SPEC_MODEL_TASKER`, `SPEC_MODEL_VALIDATOR`
- **Dependencies**: T-2, T-3, T-4

### T-7: Bump plugin version to 5.1.0

- **Status**: completed
- **Wired**: n/a
- **Verified**: yes
- **Requirements**: US-6
- **Description**: Update the version string in two files. `.claude-plugin/plugin.json`: change `"version": "5.0.3"` to `"version": "5.1.0"`. `skills/spec-workflow/SKILL.md`: change `version: 5.0.3` to `version: 5.1.0` in the YAML frontmatter. These are the only changes to these two files -- do not alter any other content.
- **Acceptance**:
  - `grep '"version"' .claude-plugin/plugin.json` outputs a line containing `"5.1.0"`
  - `grep '^version:' skills/spec-workflow/SKILL.md` outputs `version: 5.1.0`
  - No other content in either file is changed
- **Dependencies**: T-2, T-3, T-4, T-5

---

## Phase 4: Testing

### T-8: Manual test -- direct Anthropic path (backward compatibility)

- **Status**: completed
- **Wired**: n/a
- **Verified**: yes
- **Requirements**: US-2, NFR-4
- **Description**: Verify the plugin behaves identically to v5.0.3 on the direct Anthropic API path. Preconditions: `ANTHROPIC_BASE_URL` unset, no `SPEC_MODEL_*` vars set. Run these checks: (1) `bash -n` on all 8 modified shell scripts; (2) with `ANTHROPIC_BASE_URL` unset, source `scripts/lib/detect-backend.sh` and call `is_anthropic_backend` -- confirm it returns 0; (3) with `ANTHROPIC_BASE_URL` unset, run any script with `2>err.txt` and confirm `err.txt` contains no `[spec-driven]` text; (4) inspect all 11 agent files and confirm each `model:` field is exactly one of `opus`, `sonnet`, or `haiku`.
- **Acceptance**:
  - `bash -n scripts/spec-exec.sh scripts/spec-loop.sh scripts/spec-complete.sh scripts/spec-accept.sh scripts/spec-docs.sh scripts/spec-release.sh scripts/spec-verify.sh scripts/spec-retro.sh` exits 0
  - `bash -c 'ANTHROPIC_BASE_URL="" . scripts/lib/detect-backend.sh; is_anthropic_backend && echo ok'` prints `ok`
  - `bash -c 'unset ANTHROPIC_BASE_URL; . scripts/lib/detect-backend.sh' 2>err.txt; grep -c "spec-driven" err.txt` returns `0`
  - `grep "^model:" agents/*.md | grep -v "opus\|sonnet\|haiku"` returns zero lines
- **Dependencies**: T-1, T-2, T-5

### T-9: Manual test -- non-Anthropic backend banner behavior

- **Status**: completed
- **Wired**: n/a
- **Verified**: yes
- **Requirements**: US-2, US-3, NFR-1, NFR-2
- **Description**: Verify the optimization notice behavior for non-Anthropic backends. Run these checks: (1) with `ANTHROPIC_BASE_URL=http://localhost:4000` and `SPEC_QUIET` unset, source `detect-backend.sh` and confirm banner content on stderr; (2) with `ANTHROPIC_BASE_URL=http://localhost:4000` and `SPEC_QUIET=1`, confirm no banner; (3) source `detect-backend.sh` twice in the same bash process with a non-Anthropic URL and confirm banner appears exactly once; (4) confirm banner goes to stderr not stdout.
- **Acceptance**:
  - `ANTHROPIC_BASE_URL=http://localhost:4000 bash -c '. scripts/lib/detect-backend.sh' 2>b.txt; grep -c "\[spec-driven\]" b.txt` outputs `1`
  - Banner file contains all of: `http://localhost:4000`, `SPEC_MODEL_PLANNER`, `SPEC_MODEL_DEBUGGER`, `SPEC_MODEL_CONSULTANT`, `docs/advanced/model-routing.md`, `SPEC_QUIET=1`
  - `ANTHROPIC_BASE_URL=http://localhost:4000 SPEC_QUIET=1 bash -c '. scripts/lib/detect-backend.sh' 2>b.txt; wc -c < b.txt` outputs `0`
  - `ANTHROPIC_BASE_URL=http://localhost:4000 bash -c '. scripts/lib/detect-backend.sh; . scripts/lib/detect-backend.sh' 2>b.txt; grep -c "\[spec-driven\]" b.txt` outputs `1` (idempotency)
  - `ANTHROPIC_BASE_URL=http://localhost:4000 bash -c '. scripts/lib/detect-backend.sh' >stdout.txt 2>stderr.txt; [ ! -s stdout.txt ] && echo "stdout-clean"` prints `stdout-clean`
- **Dependencies**: T-1, T-5

### T-10: Manual test -- env-var override wiring and documentation audit

- **Status**: completed
- **Wired**: n/a
- **Verified**: yes
- **Requirements**: US-4, US-5, US-6
- **Description**: Two verification passes. (1) Env-var override audit: read `commands/spec.md`, `commands/spec-brainstorm.md`, `commands/spec-refine.md`, `commands/spec-tasks.md` and confirm each contains instructions naming the correct `SPEC_MODEL_*` vars with directions to pass to the Task tool `model:` parameter; confirm `commands/spec.md` validate-fix loop still contains two distinct routing conditions (spec-planner for requirement issues, spec-tasker for task issues); confirm `commands/spec-validate.md` has no `SPEC_MODEL_` text. (2) Documentation audit: run the version-string grep from design.md Test Plan 5; confirm `docs/advanced/model-routing.md` contains all required sections; verify version bump in both version files.
- **Acceptance**:
  - `grep -rn 'Opus 4\.6\|Sonnet 4\.6\|Haiku 4\.5\|claude-opus-4-6\|claude-sonnet-4-6\|claude-haiku-4-5' --include='*.md' . | grep -v '.claude/specs/spec-'` returns zero matches
  - `grep 'SPEC_MODEL_CONSULTANT' commands/spec-brainstorm.md` returns a match
  - `grep 'SPEC_MODEL_TASKER' commands/spec-tasks.md` returns a match
  - `grep 'SPEC_MODEL_' commands/spec-validate.md` returns zero matches (file unmodified)
  - `docs/advanced/model-routing.md` contains the strings `SPEC_MODEL_PLANNER`, `CCR`, `LiteLLM`, `opencode`, `SPEC_QUIET`, `deepseek-v3`
  - `grep '"version"' .claude-plugin/plugin.json` shows `5.1.0`
  - `grep '^version:' skills/spec-workflow/SKILL.md` shows `5.1.0`
  - `commands/spec.md` contains two distinct agent routing conditions in the validate-fix step (BUG-2 guard)
- **Dependencies**: T-2, T-3, T-4, T-5, T-6, T-7

---

## Phase 5: Polish

### T-11: Grep audit -- confirm no snapshot IDs remain in non-archived files

- **Status**: completed
- **Wired**: n/a
- **Verified**: yes
- **Requirements**: US-1, US-5, NFR-6
- **Description**: Run a comprehensive grep to confirm no snapshot-pinned model IDs remain anywhere in the repo outside of archived spec directories. Command: `grep -rn 'claude-opus-4-6\|claude-sonnet-4-6\|claude-haiku-4-5-20251001\|Opus 4\.6\|Sonnet 4\.6\|Haiku 4\.5' --include='*.md' --include='*.json' --include='*.sh' . | grep -v '.claude/specs/spec-'`. Any match is a failure requiring remediation. Also confirm the orphaned sync-conflict file was not modified (`commands/spec-team.sync-conflict-20260407-015530-WTRWCNZ.md` must be unchanged, NFR-6).
- **Acceptance**:
  - The grep command above returns zero matches
  - `git diff --name-only -- 'commands/spec-team.sync-conflict*'` shows no changes to the sync-conflict file
  - `grep "^model:" agents/*.md | awk -F': ' '{print $2}' | sort -u` outputs exactly three lines: `haiku`, `opus`, `sonnet`
- **Dependencies**: T-2, T-3, T-4, T-5, T-6, T-7

### T-12: Verify BUG-1 and BUG-2 regression guards are intact

- **Status**: completed
- **Wired**: n/a
- **Verified**: yes
- **Requirements**: US-1, US-2, US-3, US-4
- **Description**: Targeted regression check for the two known bugs. BUG-1 check: Confirm anti-stub enforcement text is present and unmodified in the system prompt bodies of `agents/spec-implementer.md`, `agents/spec-tester.md`, and `agents/spec-reviewer.md` (content below the closing `---` frontmatter delimiter). Also confirm the prompt template heredocs in `scripts/spec-exec.sh` and `scripts/spec-loop.sh` are unchanged. BUG-2 check: Confirm `commands/spec.md` still contains the validate-fix routing logic with two separate conditions -- vague-requirement/design issues route to `spec-planner`, task-traceability issues route to `spec-tasker`. The model override instructions added in T-3 must augment this routing, not replace it.
- **Acceptance**:
  - `agents/spec-implementer.md` system prompt body contains the word "stub" (anti-stub enforcement language present)
  - `agents/spec-tester.md` system prompt body contains the word "stub"
  - `agents/spec-reviewer.md` system prompt body contains the word "stub"
  - `grep -c 'detect-backend' scripts/spec-exec.sh` outputs `1` and the prompt heredoc in the file does not contain the string `detect-backend` (the source call is in the preamble, not the prompt)
  - `grep -c 'detect-backend' scripts/spec-loop.sh` outputs `1` and the prompt heredoc is unchanged
  - `commands/spec.md` contains references to both `spec-planner` and `spec-tasker` in distinct conditional blocks in the validate-fix step (not merged into a single unconditional call)
- **Dependencies**: T-2, T-3, T-5
