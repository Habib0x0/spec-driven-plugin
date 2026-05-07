# spec-scanner

The spec-scanner analyzes an existing codebase and produces a **project profile** — a structured summary of the tech stack, detected patterns, domain entities, and registration points. Other agents read this profile to generate wiring-aware specs and code.

## Role

Scan the codebase on first `/spec` invocation (Phase 0), detect what the project is built on, and record that intelligence in `.claude/specs/_project-profile.md` (or split files for large monorepos). The profile lives in the repo and is reused by subsequent agents.

## Model

**Standard tier.** The scanner reads many files and extracts structural information. Depth of reasoning matters less than throughput — the standard tier is the right fit for fast, accurate pattern detection.

## When It Runs

- `/spec <name>` — Phase 0 auto-scan on first invocation if no profile exists
- `/spec-scan` — manual rescan to refresh the profile after significant codebase changes

## What It Records

The project profile captures six sections:
