#!/usr/bin/env bash
# lib/spec-root.sh -- Resolve the spec directory for Codex/Claude compatibility.
# Source this file; do not execute directly.

detect_spec_root() {
  if [ -n "${SPEC_ROOT:-}" ]; then
    printf '%s\n' "$SPEC_ROOT"
  elif [ -d ".codex/specs" ]; then
    printf '%s\n' ".codex/specs"
  elif [ -d ".claude/specs" ]; then
    printf '%s\n' ".claude/specs"
  else
    printf '%s\n' ".codex/specs"
  fi
}

list_specs() {
  local spec_root="$1"
  find "$spec_root" -mindepth 1 -maxdepth 1 -type d ! -name ".worktrees" -exec basename {} \; 2>/dev/null | sort
}

require_specs_root() {
  local spec_root="$1"
  if [ ! -d "$spec_root" ]; then
    echo "Error: No specs directory found at $spec_root."
    echo "Run /spec <name> first to create a spec, or set SPEC_ROOT."
    exit 1
  fi
}
