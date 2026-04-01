# Release: Spec Intelligence Layer

## Version
**Minor** (3.1.0 -> 3.2.0) -- New feature addition with full backward compatibility. All existing commands and workflows continue to work unchanged when no project profile exists.

## Release Date
2026-04-01

## Changelog

### User-Facing Changes
- **Phase 0 Auto-Scan**: `/spec` now automatically scans your codebase on first run to detect framework patterns, entities, and registration points. No manual setup needed.
- **New `/spec-scan` command**: Explicitly trigger or refresh a codebase scan to update the project profile.
- **New `/spec-debug` command**: Standalone bug-fixing workflow that diagnoses issues, fixes them, documents everything in `diagnosis.md` and `fix.md`, and creates regression markers for future specs.
- **Parallel execution**: `/spec-loop` now runs independent tasks concurrently (up to 4 at a time). Use `--no-parallel` to force sequential execution.
- **Auto-validation**: `/spec` automatically validates the generated spec and fixes issues before presenting it -- no more manual `/spec-validate` loops.
- **Wiring-aware agents**: Implementer and tester now use project-specific registration points instead of generic checklists, significantly reducing "code exists but isn't connected" failures.

### Technical Changes
- New `spec-scanner` agent (`agents/spec-scanner.md`) with LLM-driven heuristic scanning
- New `scripts/lib/verify.sh` -- verification gate library for post-task wiring checks
- New `scripts/lib/parallel.sh` -- parallel execution library with dependency graph parsing, batch scheduling, and conflict resolution via git worktrees
- New `commands/spec-scan.md` and `commands/spec-debug.md` slash commands
- New `templates/_project-profile.md` and `templates/_profile-index.md` templates
- Modified `agents/spec-implementer.md` -- reads project profile for wiring, falls back to generic checklist
- Modified `agents/spec-tester.md` -- profile-aware integration checks + regression marker verification
- Modified `agents/spec-debugger.md` -- standalone debug mode with diagnosis/fix workflow and regression markers
- Modified `agents/spec-planner.md` -- gap detection from Entity Registry, regression warnings
- Modified `commands/spec.md` -- Phase 0 auto-scan hook + validate-fix loop
- Modified `scripts/spec-loop.sh` -- verification gates, parallel execution, `--no-parallel` flag, backward compat guards
- Modified `.claude-plugin/plugin.json` -- registered new agent and commands
- Modified `CLAUDE.md` -- documented all new capabilities
- Test files: `tests/test-scanner-output.sh`, `tests/test-parallel.sh`, `tests/test-verify.sh`, `tests/test-validate-fix.md`

### Breaking Changes
None. All changes are backward compatible:
- Projects without a profile use existing generic wiring checklists
- `spec-loop.sh` falls back to sequential execution if `parallel.sh` is missing
- Verification gates are skipped when no profile exists

## Deployment Checklist

### Pre-Deployment
- [ ] Verify `plugin.json` is valid JSON: `jq . .claude-plugin/plugin.json`
- [ ] Verify all new bash scripts pass syntax check: `bash -n scripts/lib/verify.sh && bash -n scripts/lib/parallel.sh`
- [ ] Verify all new agent/command markdown files exist and have valid YAML frontmatter
- [ ] No database migrations required
- [ ] No environment variables required
- [ ] No external service dependencies

### Deployment
- [ ] Merge to main branch
- [ ] Verify plugin loads in Claude Code (check `/help` for new commands)
- [ ] Test `/spec-scan` on a sample project
- [ ] Test `/spec-debug` with a sample bug description
- [ ] Test `/spec-loop --no-parallel` on a sample spec

### Post-Deployment
- [ ] Verify existing `/spec`, `/spec-loop`, `/spec-exec` commands still work on projects without profiles
- [ ] Test backward compatibility: remove `scripts/lib/parallel.sh` temporarily and confirm `spec-loop.sh` runs in sequential mode
- [ ] Monitor for any issues reported by plugin users

## Environment Variables
No new environment variables required.

## Database Migrations
No migrations required. This release only adds/modifies markdown files and bash scripts.

## Rollback Plan
1. Revert to the commit before the merge: `git revert --no-commit HEAD`
2. Or restore from the previous version tag
3. All changes are in markdown/bash files -- no database or infrastructure changes to roll back
4. Existing specs and projects are unaffected by rollback (the profile files just become unused artifacts)

## Contributors
- Habib Najibullah

## Stats
- 27 commits
- 5 new files created
- 9 existing files modified
- 4 test files added
- 24 spec tasks completed and verified
