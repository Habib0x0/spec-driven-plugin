#!/usr/bin/env bash
# lib/deps.sh — Cross-spec dependency checking and cycle detection
# Provides check_dependencies() and get_dependency_status() for execution scripts.
# Source this file; do not execute directly.

# _parse_depends_on(spec_name)
# Parses the "## Depends On" section from requirements.md.
# Outputs one dependency name per line. Outputs nothing if no deps.
_parse_depends_on() {
  local spec_name="$1"
  local req_file=".claude/specs/$spec_name/requirements.md"

  if [[ ! -f "$req_file" ]]; then
    return 0
  fi

  local in_section=false
  while IFS= read -r line; do
    if [[ "$line" == "## Depends On" ]]; then
      in_section=true
      continue
    fi
    # stop at next heading
    if $in_section && [[ "$line" =~ ^## ]]; then
      break
    fi
    if $in_section && [[ "$line" =~ ^-\ +(.+)$ ]]; then
      local dep="${BASH_REMATCH[1]}"
      # trim whitespace
      dep="$(echo "$dep" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      if [[ -n "$dep" ]]; then
        echo "$dep"
      fi
    fi
  done < "$req_file"
}

# _check_spec_complete(spec_name)
# Returns 0 if all tasks in the spec are complete, 1 otherwise.
# Outputs "verified_count:total_count" to stdout.
_check_spec_complete() {
  local spec_name="$1"
  local tasks_file=".claude/specs/$spec_name/tasks.md"

  if [[ ! -f "$tasks_file" ]]; then
    echo "0:0"
    return 1
  fi

  local total=0
  local verified=0
  local current_status=""
  local current_wired=""
  local current_verified=""
  local in_task=false

  while IFS= read -r line; do
    # detect task header (### T-N: ...)
    if [[ "$line" =~ ^###\ T-[0-9]+(\.[0-9]+)? ]]; then
      # check previous task if we were tracking one
      if $in_task; then
        total=$((total + 1))
        if [[ "$current_status" == "completed" ]] && \
           [[ "$current_wired" == "yes" || "$current_wired" == "n/a" ]] && \
           [[ "$current_verified" == "yes" ]]; then
          verified=$((verified + 1))
        fi
      fi
      in_task=true
      current_status=""
      current_wired=""
      current_verified=""
      continue
    fi

    if $in_task; then
      if [[ "$line" =~ ^\-\ \*\*Status\*\*:\ (.+)$ ]]; then
        current_status="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^\-\ \*\*Wired\*\*:\ (.+)$ ]]; then
        current_wired="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^\-\ \*\*Verified\*\*:\ (.+)$ ]]; then
        current_verified="${BASH_REMATCH[1]}"
      fi
    fi
  done < "$tasks_file"

  # handle last task
  if $in_task; then
    total=$((total + 1))
    if [[ "$current_status" == "completed" ]] && \
       [[ "$current_wired" == "yes" || "$current_wired" == "n/a" ]] && \
       [[ "$current_verified" == "yes" ]]; then
      verified=$((verified + 1))
    fi
  fi

  echo "$verified:$total"

  if [[ "$total" -eq 0 ]]; then
    return 1
  fi
  if [[ "$verified" -eq "$total" ]]; then
    return 0
  fi
  return 1
}

# _detect_cycle(spec_name, visited_dir, path_dir, chain)
# DFS-based circular dependency detection using temp files.
# chain is the " -> " separated path leading to this node.
# Returns 1 with error message if a cycle is found.
_detect_cycle() {
  local spec_name="$1"
  local visited_dir="$2"
  local path_dir="$3"
  local chain="$4"

  # cycle detected — this spec is already in the current path
  if [[ -f "$path_dir/$spec_name" ]]; then
    echo "Error: Circular dependency detected: $chain -> $spec_name" >&2
    return 1
  fi

  # already fully explored, no cycle through this node
  if [[ -f "$visited_dir/$spec_name" ]]; then
    return 0
  fi

  # mark as in current DFS path
  touch "$path_dir/$spec_name"
  # mark as visited globally
  touch "$visited_dir/$spec_name"

  # recurse into dependencies
  local deps
  deps="$(_parse_depends_on "$spec_name")"
  if [[ -n "$deps" ]]; then
    while IFS= read -r dep; do
      if [[ -n "$dep" ]]; then
        _detect_cycle "$dep" "$visited_dir" "$path_dir" "$chain -> $spec_name" || return 1
      fi
    done <<< "$deps"
  fi

  # remove from current path (backtrack)
  rm -f "$path_dir/$spec_name"
  return 0
}

# check_dependencies(spec_name)
# Checks all dependencies are met. Exits 1 if not.
check_dependencies() {
  local spec_name="$1"
  local deps
  deps="$(_parse_depends_on "$spec_name")"

  # no dependencies — nothing to check
  if [[ -z "$deps" ]]; then
    return 0
  fi

  # cycle detection via DFS
  local tmp_visited tmp_path
  tmp_visited="$(mktemp -d)"
  tmp_path="$(mktemp -d)"
  trap "rm -rf '$tmp_visited' '$tmp_path'" RETURN

  touch "$tmp_path/$spec_name"
  touch "$tmp_visited/$spec_name"

  while IFS= read -r dep; do
    [[ -z "$dep" ]] && continue
    _detect_cycle "$dep" "$tmp_visited" "$tmp_path" "$spec_name" || exit 1
  done <<< "$deps"

  rm -rf "$tmp_visited" "$tmp_path"
  trap - RETURN

  # check each dependency exists and is complete
  local has_failure=false
  while IFS= read -r dep; do
    [[ -z "$dep" ]] && continue

    if [[ ! -d ".claude/specs/$dep" ]]; then
      echo "Error: Dependency spec not found: $dep" >&2
      exit 1
    fi

    if [[ ! -f ".claude/specs/$dep/tasks.md" ]]; then
      echo "Error: Dependency $dep has no tasks.md" >&2
      exit 1
    fi

    local counts
    counts="$(_check_spec_complete "$dep")" || true
    local verified="${counts%%:*}"
    local total="${counts##*:}"

    if [[ "$total" -eq 0 ]] || [[ "$verified" -ne "$total" ]]; then
      echo "Error: Dependency incomplete: $dep ($verified/$total tasks verified)" >&2
      has_failure=true
    fi
  done <<< "$deps"

  if $has_failure; then
    exit 1
  fi

  return 0
}

# get_dependency_status(spec_name)
# Outputs one line per dependency: dep_name:status:verified_count:total_count
# Does not call exit on failure.
get_dependency_status() {
  local spec_name="$1"
  local deps
  deps="$(_parse_depends_on "$spec_name")"

  if [[ -z "$deps" ]]; then
    return 0
  fi

  while IFS= read -r dep; do
    [[ -z "$dep" ]] && continue

    if [[ ! -d ".claude/specs/$dep" ]] || [[ ! -f ".claude/specs/$dep/tasks.md" ]]; then
      echo "$dep:not_found:0:0"
      continue
    fi

    local counts
    counts="$(_check_spec_complete "$dep")" || true
    local verified="${counts%%:*}"
    local total="${counts##*:}"

    if [[ "$total" -gt 0 ]] && [[ "$verified" -eq "$total" ]]; then
      echo "$dep:complete:$verified:$total"
    else
      echo "$dep:incomplete:$verified:$total"
    fi
  done <<< "$deps"
}
