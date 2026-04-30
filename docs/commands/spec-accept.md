# /spec-accept

Run user acceptance testing (UAT) to verify that the implementation satisfies all spec requirements. This is the formal sign-off gate between "implementation complete" and "ready to release."

## Usage

```
/spec-accept [spec-name]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `spec-name` | No | Name of the spec to accept. Auto-detected if only one spec exists. |

## What It Does

1. **Locates the spec** and reads all spec files and task status.

2. **Runs a pre-flight check** — if tasks are still incomplete, warns you and asks whether to proceed with partial testing or finish implementation first.

3. **Asks about testing scope** — choose between a full acceptance test (all requirements), testing specific requirements by ID, or focusing on non-functional requirements (performance, accessibility, data integrity).

4. **Performs acceptance testing** — traces every EARS acceptance criterion in `requirements.md` to the corresponding verified tasks. Checks that non-functional requirements are met. Reports results per criterion with pass/fail status and details.

5. **Presents results and asks for a decision:**
   - **Accept — ready to release** — records formal sign-off and proceeds
   - **Accept with conditions** — notes minor issues for post-release follow-up
   - **Reject — needs fixes** — lists failed criteria and suggests next steps
   - **Re-test specific items** — runs the acceptor again on a subset

6. **Records the decision** — writes an `acceptance.md` file to the spec directory with the date, UAT report summary, any conditions noted, and the sign-off decision. If rejected, documents the failed criteria and suggested fixes.

## The Difference Between Testing and Acceptance

Automated tests verify that code passes tests. Acceptance testing verifies that **the right thing was built**. This command checks requirement traceability — every criterion in the spec maps to verified, reviewed work — not just whether the test suite is green.

## Example

```
/spec-accept user-authentication
```

## Tips

- Run this after all tasks are complete and `/spec-loop` has finished.
- Non-functional requirements (performance, security, accessibility) are often missed during implementation — this command explicitly checks them.
- Some criteria will be flagged as untestable automatically. The report calls these out for manual verification.
- The `acceptance.md` file becomes part of the spec record and is referenced by `/spec-release` and `/spec-retro`.
- If acceptance is rejected, use `/spec-refine` to update requirements (if the spec was wrong) or fix the implementation (if the code does not match the spec).

!!!tip
    Run `/spec-accept` before `/spec-release`. The release artifact will include the acceptance status, which is useful for audits and stakeholder communication.

## See Also

- [/spec-release](spec-release.md) — Generate release notes and deployment checklist after acceptance
- [/spec-refine](spec-refine.md) — Update requirements if acceptance reveals a spec problem
- [/spec-verify](spec-verify.md) — Post-deployment smoke tests after the release is live
