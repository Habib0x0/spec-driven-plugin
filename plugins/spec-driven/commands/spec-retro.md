---
description: Run a retrospective on a completed spec to capture lessons learned
---

# /spec-retro

Analyze a completed spec's lifecycle to generate a retrospective — what went well, what caused friction, and what to improve next time. This closes the feedback loop for continuous process improvement.

## Philosophy

Without retrospectives, the same mistakes repeat. This command automates the data gathering (progress logs, debugging cycles, reviewer rejections, spec changes) and facilitates a structured conversation about process improvements.

## Workflow

### 1. Locate the Spec

If a spec name is provided, use it. Otherwise auto-detect from `.claude/specs/`.

### 2. Gather Data

Collect metrics from the spec's lifecycle:

**From `progress.md`** (append-only session log):
- Number of implementation sessions
- Tasks that required multiple attempts
- Integration issues logged
- Blockers encountered

**From `tasks.md`:**
- Total tasks planned vs. completed
- Tasks added mid-implementation (scope creep?)
- Task complexity distribution
- Which phases had the most tasks (Setup, Core, Integration, Testing, Polish)

**From git log** (use Bash):
- Number of commits for this feature
- Time span from first to last commit
- Frequency of "fix" or "debug" commits vs. feature commits
- Number of authors involved

**From `acceptance.md`** (if exists):
- First-pass acceptance rate
- Criteria that failed initially

**From `release.md`** (if exists):
- Any post-deployment issues noted

**From spec history** (if git tracks changes):
- Number of times requirements.md was modified after initial creation
- Number of times design.md was modified after initial creation
- Scope changes during implementation

### 3. Automated Analysis

Before involving the user, analyze the data for patterns:

**Positive signals:**
- High first-pass acceptance rate
- Few debugging cycles
- Tasks completed in order (good dependency planning)
- No spec modifications during implementation (requirements were solid)

**Friction signals:**
- Tasks requiring 3+ debugging cycles → requirements or design gap
- Reviewer rejections → implementation quality or spec ambiguity
- Many "fix" commits → incomplete testing or unclear acceptance criteria
- Spec modifications mid-implementation → requirements changed or were incomplete
- Integration tasks failing → architecture missed dependencies
- Scope additions → brainstorming/requirements phase was rushed

### 4. Facilitated Discussion

Present the automated analysis and engage the user in a conversation:

**Round 1 — What went well:**
*"Based on the data, here's what went smoothly: [positive signals]. Does that match your experience? What else went well?"*

Use AskUserQuestion:
- **Agree with analysis** — Move to friction
- **Add more positives** — Let them share
- **Disagree** — Discuss their perspective

**Round 2 — What caused friction:**
*"Here's where I see friction: [friction signals with data]. Were there other pain points?"*

Use AskUserQuestion:
- **Agree, these were the main issues**
- **There were other issues too** — Let them share
- **Some of these weren't actually problems** — Discuss

**Round 3 — Improvements:**
*"For next time, I'd suggest: [recommendations based on friction]. What improvements would you prioritize?"*

Use AskUserQuestion:
- **Agree with recommendations**
- **I have different priorities** — Let them share
- **Let's discuss trade-offs** — Deeper conversation

### 5. Generate Retrospective

Write to `.claude/specs/<feature-name>/retro.md`:

```markdown
## Retrospective: [Feature Name]

### Date
[current date]

### Metrics
| Metric | Value |
|--------|-------|
| Total tasks | X |
| Tasks completed | X |
| Implementation sessions | X |
| Debugging cycles | X |
| Spec modifications | X |
| Commits | X |
| First-pass acceptance rate | X% |

### What Went Well
- [Item with supporting data]
- [Item with supporting data]
- [User-contributed item]

### What Caused Friction
- [Item with supporting data and impact]
- [Item with supporting data and impact]
- [User-contributed item]

### Root Causes
For each friction point:
- **[Friction item]**: [Root cause analysis — was it a requirements gap, design issue, tooling problem, or process gap?]

### Action Items
| Action | Priority | Applies To |
|--------|----------|------------|
| [Specific improvement] | High/Medium/Low | [Future specs / this team / tooling] |
| [Another improvement] | High/Medium/Low | [scope] |

### User Notes
[Any additional observations from the user]
```

### 6. Summary

Present key takeaways:
- Top 3 things that worked well (keep doing these)
- Top 3 improvements to make (for the next spec)
- Any tooling or process changes to consider

Suggest: *"These insights will improve your next `/spec` workflow. Consider reviewing this retro before starting your next feature."*

## Tips

- Run this while the feature is still fresh in mind — don't wait weeks
- The automated analysis is a starting point, not the final word — user input matters most
- Action items should be specific and actionable, not vague ("improve testing" → "add integration test tasks for API endpoints in spec-tasker")
- Keep retrospectives blame-free — focus on process, not people
- If this is the first retro, there's no baseline — that's fine, it establishes one
- Over time, retros across multiple specs reveal systemic patterns
