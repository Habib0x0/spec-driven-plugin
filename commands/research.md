---
name: research
description: "Deep research before planning. Launches parallel agents to search docs, web, and codebase, then synthesizes findings into actionable context."
argument-hint: "[topic or question]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - AskUserQuestion
  - Task
  - WebSearch
  - WebFetch
---

$ARGUMENTS

Research this thoroughly before any planning or implementation begins.

## How to research

### Step 1: Clarify before you research (MANDATORY — never skip)

Before reading a single file or launching any agent, use AskUserQuestion. Read the input and identify every place where you have 2+ plausible interpretations — scope, intent, constraints, approach, priority. Ask about those specifically.

**How to ask:** Present choices tailored to the actual input, not generic categories. The options should come directly from the ambiguities in what was asked. If you see three plausible ways to interpret what the user wants, list those three things and ask which is closest. Don't ask what you can already infer. Do ask anything that would materially change what you research or recommend.

Good trigger conditions for asking:
- The input describes a symptom but not a root cause — ask what they think the cause is, with options
- The input proposes a solution — ask if the solution is required or just a starting hypothesis
- The scope is fuzzy — ask whether they want a targeted fix or a broader rethink, with examples of each
- Multiple approaches exist with real tradeoffs — ask which tradeoffs matter most to them
- The change could affect related systems — ask whether those are in scope
- Any constraint (time, backwards-compat, file/dependency, team conventions) is unstated — ask

Keep questions short. Use choices and options, not open prompts. "Which of these is closer?" beats "Can you describe your constraints?". An "other/none of these" escape hatch is always fine to include.

Ask as many questions as the ambiguity warrants — but batch them into a single AskUserQuestion call so the user responds once.

**Do not launch any agents until you have the answers.**

### Step 2: Parse intent

With the answers in hand, read critically:
- What is the **core problem** — distinct from the proposed solution?
- Does any answer change the scope or approach from what was originally described?
- Are there remaining ambiguities? If yes, use AskUserQuestion again — don't bank on assumptions.
- Frame 2-4 specific research questions around the problem.

Then immediately launch parallel research — do not confirm the research questions with the user first.

### Step 3: Launch parallel research

Spawn sub-agents to work simultaneously. Match agent count to complexity — not all are always needed:

- **Codebase agent** (almost always): Grep/Glob/Read to find relevant patterns, existing implementations, related code, config, and dependencies in the current project.
- **Docs agent** (when libraries/frameworks involved): Look up documentation. Try Context7 MCP tools first (mcp__context7__resolve_library_id, mcp__context7__get_library_docs). If Context7 is unavailable, use WebSearch + WebFetch targeting official docs sites.
- **Web agent** (when the problem isn't purely local): WebSearch for similar problems, solutions, examples, blog posts, Stack Overflow answers, GitHub issues. Focus on recent and authoritative sources.
- **Dependencies agent** (when relevant): Check package versions, compatibility, breaking changes, config options. Read package.json/Gemfile/requirements.txt/etc and cross-reference with docs.
- **UI agent** (when the change affects visual design): Research visual design implications — layout, visual hierarchy, typography, color, spacing, responsive behavior, animation, and consistency with existing design language. Use the `/ui` skill when available. Look at what design system components exist and whether the proposed change introduces visual inconsistencies.
- **UX agent** (when the change affects user-facing behavior): Research interaction patterns, user flows, cognitive load, affordances, error states, edge cases, and accessibility (WCAG compliance, keyboard navigation, screen reader behavior). Search the codebase for how similar interactions are handled today. WebSearch for established UX patterns relevant to the problem.
- **Delight agent** (when the change touches anything a user sees or interacts with): Research opportunities to make this change feel genuinely good — micro-interactions, smart defaults, helpful empty states, smooth transitions. Search the codebase for existing delight patterns. The bar: would a user notice and think "nice"? Delight is the absence of friction plus a moment of care. Skip anything that adds complexity without genuine user payoff.

**Research the problem, not the proposal.** If the input includes a proposed solution, every agent should research the underlying problem independently first. Don't anchor on the proposed approach — it may be correct, but verify.

Each agent should return: what it found, where it found it (file paths or URLs), and key snippets.

### Step 4: Check in after research (MANDATORY)

After agents return, use AskUserQuestion before synthesizing. Summarize the key finding in a sentence or two, then surface anything unexpected and ask the user to react. Present specific choices about how to proceed — don't just ask "does this make sense?"

If findings contradict the user's stated understanding of the problem, that's especially important to surface before moving forward.

### Step 5: Synthesize

Combine all agent findings. Resolve contradictions. Identify what is confirmed vs. uncertain.

**If the input included a proposed solution:** Explicitly evaluate it. Is it the best approach, or is there a simpler way? If the proposal is unnecessary, overly complex, or solves the wrong thing, say so and recommend the better path.

### Step 6: Stress-test the recommendation

Actively look for downsides of the recommended approach. What UX does it degrade? What edge cases does it miss? What maintenance burden does it create? What could it break? Be specific — "this could be slow" is useless, "this adds an N+1 query on every page load" is useful.

## Output format

Keep it tight. No filler.

### Answer
Direct response to what was asked. Concise for simple questions, thorough when complexity demands it.

### Evidence
Code snippets, doc quotes, or data that back up the answer. Use code blocks with file paths.

### Sources
- File paths for codebase findings
- URLs for web/doc findings

### Related
Anything else discovered that the user should know — gotchas, related patterns, upcoming deprecations, alternative approaches. Skip if nothing worth mentioning.

### Downsides & Risks
What could go wrong with the recommended approach? Be specific. Skip if the solution is trivially safe.

## Rules

- **AskUserQuestion fires at Steps 1 and 4 at minimum.** More is fine — the bar for asking is low.
- **Questions must be specific to the input.** No generic category buckets. The options you present should come from the actual ambiguities in what was asked.
- **Use choices, not open prompts.** "Which of these is closer?" is better than "Can you describe X?"
- Never launch agents before completing Step 1. Never.
- Never confirm research questions with the user before launching agents — just launch them.
- Prefer primary sources (official docs, source code) over blog posts.
- If you find conflicting information, say so and state which source you trust more.
- Never pad the output. If the answer is simple, the research output should be simple.
- The number of agents should match the problem. Don't launch 4 agents for a one-file bug.
