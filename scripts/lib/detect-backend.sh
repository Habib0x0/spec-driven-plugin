#!/usr/bin/env bash
# lib/detect-backend.sh -- CLI/backend detection and optimization notice
# Source this file; do not execute directly.

# detect_cli()
# Prints the detected CLI name (codex, claude, custom, unknown).
detect_cli() {
  if [ -n "${SPEC_AGENT_CMD:-}" ]; then
    printf 'custom\n'
    return
  fi
  if command -v codex >/dev/null 2>&1; then
    printf 'codex\n'
    return
  fi
  if command -v claude >/dev/null 2>&1; then
    printf 'claude\n'
    return
  fi
  printf 'unknown\n'
}

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

  if [ "${SPEC_QUIET:-}" = "1" ]; then
    return
  fi

  CLI=$(detect_cli)
  NON_ANTHROPIC=false
  if ! is_anthropic_backend; then
    NON_ANTHROPIC=true
  fi

  # Show notice for non-Anthropic backends OR when using Codex (which doesn't support tier aliases)
  if [ "$NON_ANTHROPIC" = true ] || [ "$CLI" = "codex" ]; then
    cat >&2 <<NOTICE

[spec-driven] Model routing notice
  CLI: ${CLI}
  ${NON_ANTHROPIC:+Backend URL: ${ANTHROPIC_BASE_URL}\n  }The spec-driven plugin uses three capability tiers: reasoning, standard, lightweight.
  ${CLI:+Your CLI (${CLI}) does not resolve tier aliases automatically. }You can optimize
  agent performance by mapping each agent to a model your backend supports:

    export SPEC_MODEL_PLANNER=<your-reasoning-model>
    export SPEC_MODEL_REVIEWER=<your-reasoning-model>
    export SPEC_MODEL_TASKER=<your-standard-model>
    export SPEC_MODEL_IMPLEMENTER=<your-standard-model>
    export SPEC_MODEL_TESTER=<your-standard-model>
    export SPEC_MODEL_VALIDATOR=<your-standard-model>
    export SPEC_MODEL_DEBUGGER=<your-lightweight-model>
    export SPEC_MODEL_SCANNER=<your-standard-model>
    export SPEC_MODEL_ACCEPTOR=<your-standard-model>
    export SPEC_MODEL_DOCUMENTER=<your-standard-model>
    export SPEC_MODEL_CONSULTANT=<your-standard-model>

  Examples:
    OpenAI:   export SPEC_MODEL_PLANNER=o1 SPEC_MODEL_TASKER=gpt-4o
    DeepSeek: export SPEC_MODEL_PLANNER=deepseek-reasoner SPEC_MODEL_TASKER=deepseek-chat
    Google:   export SPEC_MODEL_PLANNER=gemini-1.5-pro SPEC_MODEL_TASKER=gemini-1.5-pro

  See: docs/advanced/model-routing.md
  Suppress this notice: export SPEC_QUIET=1

NOTICE
  fi
fi
