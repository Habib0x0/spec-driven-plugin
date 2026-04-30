#!/usr/bin/env bash
# Bump version across all 4 version files, insert CHANGELOG entry, and commit.
# Usage: bash scripts/bump-version.sh <patch|minor|major> [--push]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  echo "Usage: $0 <patch|minor|major> [--push]"
  exit 1
}

[[ $# -lt 1 ]] && usage

BUMP_TYPE="$1"
PUSH=false
[[ "${2:-}" == "--push" ]] && PUSH=true

case "$BUMP_TYPE" in
  patch|minor|major) ;;
  *) usage ;;
esac

# Read current version from the canonical source
PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
CURRENT=$(grep '"version"' "$PLUGIN_JSON" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

if [[ -z "$CURRENT" ]]; then
  echo "error: could not read version from $PLUGIN_JSON" >&2
  exit 1
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

case "$BUMP_TYPE" in
  patch) PATCH=$((PATCH + 1)) ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
esac

NEW="$MAJOR.$MINOR.$PATCH"
TODAY=$(date +%Y-%m-%d)

echo "Bumping $CURRENT -> $NEW ($BUMP_TYPE)"

# --- Update version files ---

# .claude-plugin/plugin.json
sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW\"/" "$PLUGIN_JSON"

# .claude-plugin/marketplace.json
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"
sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW\"/" "$MARKETPLACE_JSON"

# .codex-plugin/plugin.json
CODEX_JSON="$REPO_ROOT/.codex-plugin/plugin.json"
sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW\"/" "$CODEX_JSON"

# skills/spec-workflow/SKILL.md
SKILL_MD="$REPO_ROOT/skills/spec-workflow/SKILL.md"
sed -i '' "s/version: $CURRENT/version: $NEW/" "$SKILL_MD"

echo "Updated version files."

# --- Insert CHANGELOG entry ---

CHANGELOG="$REPO_ROOT/CHANGELOG.md"

# Build the new entry block
NEW_ENTRY="## [$NEW] - $TODAY

### <!-- describe changes here -->

"

# Insert after the first line that starts with "## [Unreleased]" or after the header block.
# Strategy: insert after the first "## [" line if one exists, otherwise after line 1.
if grep -q "^## \[Unreleased\]" "$CHANGELOG"; then
  # Replace the Unreleased section header with the versioned one and re-add Unreleased
  UNRELEASED_BLOCK="## [Unreleased]

"
  # Use awk: when we hit the Unreleased heading, print it, then the blank line, then the new entry
  awk -v entry="## [$NEW] - $TODAY
" '
    /^\#\# \[Unreleased\]/ {
      print $0
      print ""
      print entry
      next
    }
    { print }
  ' "$CHANGELOG" > "$CHANGELOG.tmp" && mv "$CHANGELOG.tmp" "$CHANGELOG"
else
  # Insert after the first heading line (# Changelog ...)
  awk -v entry="$NEW_ENTRY" '
    NR==1 { print; print ""; print entry; next }
    { print }
  ' "$CHANGELOG" > "$CHANGELOG.tmp" && mv "$CHANGELOG.tmp" "$CHANGELOG"
fi

echo "Inserted CHANGELOG entry for $NEW."
echo ""
echo ">>> Edit CHANGELOG.md to fill in the release notes, then run:"
echo "    git add -A && git commit -m \"chore(release): bump to $NEW\""
[[ "$PUSH" == true ]] && echo "    git push"
echo ""

# Verify all files got the new version
MISMATCHES=()
for f in "$PLUGIN_JSON" "$MARKETPLACE_JSON" "$CODEX_JSON"; do
  if ! grep -q "\"version\": \"$NEW\"" "$f"; then
    MISMATCHES+=("$f")
  fi
done
if ! grep -q "version: $NEW" "$SKILL_MD"; then
  MISMATCHES+=("$SKILL_MD")
fi

if [[ ${#MISMATCHES[@]} -gt 0 ]]; then
  echo "WARNING: version mismatch in:" >&2
  printf '  %s\n' "${MISMATCHES[@]}" >&2
  exit 1
fi

echo "All version files verified at $NEW."

# Stage and commit
cd "$REPO_ROOT"
git add \
  ".claude-plugin/plugin.json" \
  ".claude-plugin/marketplace.json" \
  ".codex-plugin/plugin.json" \
  "skills/spec-workflow/SKILL.md" \
  "CHANGELOG.md"

git commit -m "chore(release): bump to $NEW"

if [[ "$PUSH" == true ]]; then
  git push
  echo "Pushed."
fi
