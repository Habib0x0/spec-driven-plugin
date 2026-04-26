#!/usr/bin/env bash
# lib/agent-runner.sh -- Run prompts through Codex by default, Claude as fallback.
# Source this file; do not execute directly.

run_agent_prompt() {
  local prompt="$1"
  local backend="${SPEC_AGENT_BACKEND:-auto}"

  if [ -n "${SPEC_AGENT_CMD:-}" ]; then
    printf '%s\n' "$prompt" | sh -c "$SPEC_AGENT_CMD"
    return $?
  fi

  if { [ "$backend" = "auto" ] || [ "$backend" = "codex" ]; } && command -v codex >/dev/null 2>&1; then
    printf '%s\n' "$prompt" | codex exec --full-auto -
    return $?
  fi

  if { [ "$backend" = "auto" ] || [ "$backend" = "claude" ]; } && command -v claude >/dev/null 2>&1; then
    claude --dangerously-skip-permissions -p "$prompt"
    return $?
  fi

  echo "Error: no supported agent CLI found. Install Codex, install Claude Code, or set SPEC_AGENT_CMD." >&2
  return 127
}

run_agent_prompt_file() {
  local prompt_file="$1"
  run_agent_prompt "$(cat "$prompt_file")"
}
