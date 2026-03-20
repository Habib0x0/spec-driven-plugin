# spec-acceptor

The spec-acceptor runs after all implementation tasks are complete. It answers a different question than the tester: not "does the code work?" but "did we build the right thing?"

## Role

Map every EARS acceptance criterion from `requirements.md` to completed, verified tasks, verify non-functional requirements, and produce a formal UAT report with a clear accept or reject recommendation.

## Model

**Sonnet.** Acceptance testing is systematic traceability work — read requirements, cross-reference tasks, check verification status, evaluate non-functional criteria. Sonnet handles this structured analysis quickly.

## When It Runs

- `/spec-accept` — invoked explicitly after implementation is complete
- `spec-accept.sh` — called from the post-implementation script pipeline, outputs `ACCEPTED` or `REJECTED` for use in CI/CD

## What It Does

The acceptor does not re-run functional tests. The tester already verified that each task works. The acceptor's job is the layer above that.

**Acceptance matrix** — For each user story in `requirements.md`, the acceptor lists every acceptance criterion and maps it to the tasks that implement it. It checks whether those tasks are marked `Verified: yes` and whether they were approved by the reviewer.

**Traceability check** — Confirms that every acceptance criterion has at least one implementing task. Flags unimplemented criteria, unverified tasks, and orphaned tasks that don't link back to any requirement.

**Non-functional requirements** — Checks what the tester and reviewer don't cover: obvious performance bottlenecks (N+1 queries, missing indexes), accessibility (semantic HTML, ARIA labels, keyboard navigation), and data integrity (validation, constraints, transaction boundaries). Security is handled by the reviewer; the acceptor references those results rather than re-checking.

**UAT report** — Produces a structured report with a traceability matrix, pass/fail/partial/untestable result per acceptance criterion, a non-functional requirements table, details on any failures, and a final recommendation: ACCEPT, REJECT, or CONDITIONAL.

## Key Rules

- Trusts the tester's functional verification — does not re-test what is already verified.
- Trusts the reviewer's security assessment — references those results rather than duplicating them.
- Every result in the report must cite evidence: task references or code references.
- A criterion is PARTIAL when some aspects are covered and others are not — the report explains what is missing.
- A criterion is UNTESTABLE when it cannot be verified automatically — the report explains why and suggests a manual test.
