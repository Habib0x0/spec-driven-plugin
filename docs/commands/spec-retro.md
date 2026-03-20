# /spec-retro

Run a structured retrospective on a completed spec. Analyzes metrics from the feature's lifecycle — implementation sessions, debugging cycles, spec changes, commit history — and facilitates a conversation about what went well and what to improve next time.

## Usage

```
/spec-retro [spec-name]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `spec-name` | No | Name of the spec to retrospect on. Auto-detected if only one spec exists. |

## What It Does

1. **Locates the spec** and reads all lifecycle artifacts: `tasks.md`, `progress.md`, `acceptance.md`, `release.md`, and git history.

2. **Collects metrics** automatically:
   - Number of implementation sessions and tasks requiring multiple attempts
   - Tasks added mid-implementation (scope creep indicator)
   - Ratio of feature commits to fix/debug commits
   - First-pass acceptance rate and which criteria failed initially
   - Number of times `requirements.md` or `design.md` were modified after initial creation

3. **Identifies patterns** before the conversation begins:
   - Positive signals: high first-pass acceptance, few debugging cycles, no spec modifications during implementation
   - Friction signals: tasks requiring many debugging cycles, reviewer rejections, spec changes mid-implementation, integration failures, scope additions

4. **Facilitates a three-round discussion:**
   - Round 1 — What went well (presents positive signals, asks for agreement or additions)
   - Round 2 — What caused friction (presents friction signals with data, asks for other pain points)
   - Round 3 — Improvements (suggests specific actions, asks which to prioritize)

5. **Generates `retro.md`** in the spec directory with:
   - Metrics table
   - What went well (data-backed)
   - What caused friction (with root cause analysis)
   - Action items with priority and scope
   - User notes from the discussion

6. **Summarizes key takeaways** — top 3 things to keep doing, top 3 improvements for the next spec.

## Example

```
/spec-retro user-authentication
```

## Tips

- Run this while the feature is still fresh. Do not wait weeks after deployment.
- The automated analysis is a starting point. Your own observations matter more than the metrics.
- Action items should be specific, not vague. "Improve testing" is not an action item. "Add integration test tasks for API endpoints in the tasks template" is.
- Keep retrospectives focused on process, not individuals.
- If this is the first retro, there is no baseline to compare against — that is fine. It establishes one for future comparisons.
- Over time, retrospectives across multiple specs reveal systemic patterns that are hard to see on a single feature.

!!!tip
    Review the previous retro's action items before starting a new spec. The value of retrospectives compounds over time only if the improvements are actually applied.

## See Also

- [/spec-accept](spec-accept.md) — Acceptance testing results feed into the retro's first-pass rate metric
- [/spec-verify](spec-verify.md) — Post-deployment issues can be captured in the retro
- [/spec](spec.md) — Start the next spec with lessons learned applied
