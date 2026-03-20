# spec-consultant

The spec-consultant is a parameterized domain expert spawned during `/spec-brainstorm` sessions. Multiple consultant instances can run in parallel, each taking on a different expert persona to analyze a feature idea from multiple angles before a spec is written.

## Role

Provide focused, codebase-specific analysis from the perspective of an assigned domain — security, architecture, UX, performance, or any other area relevant to the discussion.

## Model

**Sonnet.** Consultant analysis is bounded: a specific question, a specific codebase, a specific expert lens. Sonnet handles this efficiently and can be run in parallel across multiple expert personas simultaneously.

## When It Runs

- `/spec-brainstorm` — spawned by the Lead when expert consultation is requested (one instance per expert role)
- Each consultant runs independently and returns its analysis to the Lead, which synthesizes inputs into a brainstorm summary

## What It Does

Each consultant instance receives its expert persona, the brainstorm discussion summary, and a specific question to answer. It then:

1. Reads the discussion context and the specific question it has been asked.
2. Investigates the actual codebase — uses Glob, Grep, and Read to find relevant existing code, patterns, and architecture decisions that bear on the question.
3. Applies its domain expertise to what it finds.
4. Returns a structured analysis covering: an assessment, key concerns, specific recommendations, design constraints the feature must respect, and alternatives considered.

The output is deliberately specific to the current codebase and discussion — not generic advice. If the consultant finds something relevant in the code that wasn't mentioned in the discussion, it surfaces it.

## Key Rules

- Read-only: the consultant never modifies files or suggests implementing changes directly. It recommends approaches for the Lead and user to decide on.
- Stays focused on the specific question asked — no scope creep into adjacent concerns.
- References actual files and patterns found in the codebase, not hypothetical examples.
- Limits output to what is actionable — no filler or restating of obvious points.
- Analysis is returned to the Lead, not presented directly to the user.
