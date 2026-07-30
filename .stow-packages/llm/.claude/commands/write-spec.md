---
description: Write a spec with TDD structure and worktree isolation
argument-hint: [topic-or-requirements]
---

# /write-spec

## Purpose

Write a spec that favours red-green TDD, organizes work for worktree isolation, and is coherent.

## Contract

**Inputs:** `$ARGUMENTS` — (optional) topic, feature description, or requirements. If not provided, infer from conversation context.
**Outputs:** A spec file written to disk

## Instructions

1. **Gather context:**
   - Use `$ARGUMENTS` as the basis, or infer from conversation context
   - If nothing can be inferred, ask the user

2. **Write the spec** applying TDD discipline as applicable:
   - Each requirement should answer: "What failing test would prove this works?"
   - Define behavior precisely enough for assertions
   - Order steps for incremental red-green-refactor
   - Keep API boundaries clean

3. **Plan worktree isolation:**
   - Break work into independent chunks suitable for `wt` (worktrunk) worktrees
   - Each chunk: a logical unit that can be developed, tested, and merged independently
   - Specify which chunks can be parallelized vs have sequential dependencies

4. **Check coherence:** does each step build only on the ones before it, do the parts agree, and is anything missing that would leave a half-finished state? Then ask whether you answered the question asked or an easier one, and whether your confidence rests on evidence or on the text simply reading well.

5. **Write the file:**
   - Save to project root or `specs/` or `plans/` directory if one exists
   - Name descriptively: e.g., `spec-auth-flow.md`
   - Tell the user where it was written

## Constraints

- Every requirement must be testable — if it can't be expressed as a failing test, rewrite it
- Keep scope tight — write what was asked for, don't expand
- Be specific: vague requirements must be quantified or removed
- The spec is a contract for implementation, not a narrative
