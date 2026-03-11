#!/bin/bash
set -e

SPEC_NAME=""
VERSION_BUMP="minor"
CREATE_TAG=false
CREATE_RELEASE=false

# parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --spec-name)
      SPEC_NAME="$2"
      shift 2
      ;;
    --version-bump)
      VERSION_BUMP="$2"
      shift 2
      ;;
    --tag)
      CREATE_TAG=true
      shift
      ;;
    --release)
      CREATE_RELEASE=true
      CREATE_TAG=true  # release implies tag
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: spec-release.sh [--spec-name <name>] [--version-bump <patch|minor|major>] [--tag] [--release]"
      echo ""
      echo "Options:"
      echo "  --spec-name      Spec name (auto-detected if only one exists)"
      echo "  --version-bump   Version bump type: patch, minor (default), major"
      echo "  --tag            Create a git tag after generating release notes"
      echo "  --release        Create a GitHub release (implies --tag)"
      exit 1
      ;;
  esac
done

# auto-detect spec if not provided
if [ -z "$SPEC_NAME" ]; then
  if [ ! -d ".claude/specs" ]; then
    echo "Error: No .claude/specs directory found."
    echo "Run /spec <name> first to create a spec."
    exit 1
  fi

  SPECS=($(ls -d .claude/specs/*/  2>/dev/null | xargs -I{} basename {}))

  if [ ${#SPECS[@]} -eq 0 ]; then
    echo "Error: No specs found in .claude/specs/"
    exit 1
  elif [ ${#SPECS[@]} -eq 1 ]; then
    SPEC_NAME="${SPECS[0]}"
    echo "Auto-detected spec: $SPEC_NAME"
  else
    echo "Error: Multiple specs found. Please specify one with --spec-name:"
    for s in "${SPECS[@]}"; do
      echo "  $s"
    done
    exit 1
  fi
fi

SPEC_DIR=".claude/specs/$SPEC_NAME"

if [ ! -d "$SPEC_DIR" ]; then
  echo "Error: Spec directory not found: $SPEC_DIR"
  exit 1
fi

for f in requirements.md design.md tasks.md; do
  if [ ! -f "$SPEC_DIR/$f" ]; then
    echo "Error: Missing $f in $SPEC_DIR"
    exit 1
  fi
done

# build prompt
PROMPT_FILE=$(mktemp)
OUTPUT_FILE=$(mktemp)
trap "rm -f $PROMPT_FILE $OUTPUT_FILE" EXIT

{
  echo "# Release Preparation: $SPEC_NAME"
  echo ""
  echo "## Version Bump: $VERSION_BUMP"
  echo "## Create Tag: $CREATE_TAG"
  echo "## Create GitHub Release: $CREATE_RELEASE"
  echo ""
  echo "## Requirements"
  cat "$SPEC_DIR/requirements.md"
  echo ""
  echo "## Design"
  cat "$SPEC_DIR/design.md"
  echo ""
  echo "## Tasks"
  cat "$SPEC_DIR/tasks.md"
  if [ -f "$SPEC_DIR/acceptance.md" ]; then
    echo ""
    echo "## Acceptance Report"
    cat "$SPEC_DIR/acceptance.md"
  fi
  if [ -f "$SPEC_DIR/progress.md" ]; then
    echo ""
    echo "## Progress Log"
    cat "$SPEC_DIR/progress.md"
  fi
  cat << EOF

## Instructions

You are preparing a **release** for this feature.

### Step 1: Gather Context
1. Read the spec files above.
2. Check \`git log\` for commits related to this feature.
3. Identify: completed tasks, data model changes, new env vars, breaking changes.

### Step 2: Generate Release Notes
Write \`release.md\` to \`$SPEC_DIR/release.md\` with:

\`\`\`markdown
## Release: $SPEC_NAME

### Version
$VERSION_BUMP — [rationale]

### Release Date
[today's date]

### Changelog

#### User-Facing Changes
- [Changes written for end users, derived from user stories]

#### Technical Changes
- [Changes written for developers, derived from tasks]

#### Breaking Changes
- [Any breaking changes with migration path]

### Deployment Checklist

#### Pre-Deployment
- [ ] Database migrations applied: [list]
- [ ] Environment variables set: [list]
- [ ] External services configured: [list]
- [ ] Rollback plan reviewed

#### Deployment
- [ ] Deploy to staging
- [ ] Run smoke tests on staging
- [ ] Deploy to production
- [ ] Run smoke tests on production

#### Post-Deployment
- [ ] Verify health checks pass
- [ ] Monitor error rates for 30 minutes
- [ ] Notify stakeholders

### Environment Variables
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
[list from design.md and code]

### Database Migrations
[Schema changes or "No migrations required"]

### Rollback Plan
[Steps to revert this release]

### Contributors
[From git log]
\`\`\`

### Step 3: Tag and Release (if requested)
EOF

  if [ "$CREATE_TAG" = true ]; then
    cat << 'EOF'
- Determine the version number based on the version bump type and existing tags.
- Create a git tag: `git tag -a v<version> -m "<spec-name> release"`
EOF
  fi

  if [ "$CREATE_RELEASE" = true ]; then
    cat << EOF
- Create a GitHub release: \`gh release create v<version> --title "$SPEC_NAME" --notes-file $SPEC_DIR/release.md\`
EOF
  fi

  cat << 'EOF'

### Completion
When release.md is written (and tag/release created if requested), output <promise>RELEASED</promise>

CRITICAL RULES:
- Changelog should be user-readable, not developer jargon.
- Deployment checklist must be specific to THIS feature (not generic).
- Breaking changes MUST include migration paths.
- Rollback plan must be actionable.
- Do NOT skip the environment variables section — missing env vars are the #1 deployment failure.
EOF
} > "$PROMPT_FILE"

echo "=== Preparing release for: $SPEC_NAME (version bump: $VERSION_BUMP) ==="
[ "$CREATE_TAG" = true ] && echo "Will create git tag"
[ "$CREATE_RELEASE" = true ] && echo "Will create GitHub release"
claude --dangerously-skip-permissions "$(cat $PROMPT_FILE)"
