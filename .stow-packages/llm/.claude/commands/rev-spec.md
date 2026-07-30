---
description: Review a spec for TDD structure, design principles, and coherence
argument-hint: <spec-file-or-path>
---

# /rev-spec

## Purpose

Review a spec so it aggressively favours red-green TDD, applies design principles, and is sequentially and holistically coherent.

## Contract

**Inputs:** `$ARGUMENTS` — path to the spec file to review
**Outputs:** Reviewed spec with TDD-oriented revisions, design feedback, and coherence findings

## Instructions

1. **Validate inputs:**
   - Check that `$ARGUMENTS` points to a readable file
   - If no file, ask the user which spec to review

2. **Review** applying TDD discipline as applicable:
   - Can each requirement be expressed as a failing test first?
   - Are acceptance criteria specific enough for assertions?
   - Are API boundaries clean?
   - Is the implementation sequence ordered for incremental red-green-refactor?
   - Are frontend patterns correct? (if UI work present)

3. **Check coherence:** does each step build only on the ones before it, do the parts agree, and is anything missing that would leave a half-finished state? Then ask whether you answered the question asked or an easier one, and whether your confidence rests on evidence or on the text simply reading well.

4. **Output:**
   - **TDD & API findings** — what to restructure for testability and clean interfaces
   - **Frontend findings** (if applicable)
   - **Coherence findings** — conflicts, ordering issues, or gaps
   - **Revised spec** (only if concrete issues found)

## Constraints

- Preserve the author's intent and scope — restructure for testability, don't expand
- Cite the exact spec section when flagging an issue
- Don't rewrite the spec unless there are concrete issues
