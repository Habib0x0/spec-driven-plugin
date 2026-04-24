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
