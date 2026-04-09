---
description: Review a plan for TDD structure, design principles, and coherence
argument-hint: [plan-file-path]
---

# /rev-plan

## Purpose

Review a plan so it aggressively favours red-green TDD, applies design principles, and is sequentially and holistically coherent.

## Contract

**Inputs:** `$ARGUMENTS` — (optional) path to the plan file. If not provided, infer from conversation context.
**Outputs:** Reviewed plan with TDD-oriented revisions, design feedback, and coherence findings

## Instructions

1. **Locate the plan:**
   - If `$ARGUMENTS` points to a readable file, use it
   - Otherwise, identify from conversation context
   - If nothing found, ask the user

2. **Review** applying TDD discipline and frontend skills rules as applicable:
   - Can each task be expressed as a failing test first?
   - Are acceptance criteria specific enough for assertions?
   - Are API boundaries clean?
   - Is the implementation sequence ordered for incremental red-green-refactor?
   - Are frontend patterns correct? (if UI work present)

3. **Run the coherence check** per the coherence-check rule.

4. **Output:**
   - **TDD & API findings** — what to restructure for testability and clean interfaces
   - **Frontend findings** (if applicable)
   - **Coherence findings** — conflicts, ordering issues, or gaps
   - **Revised plan** (only if concrete issues found)

## Constraints

- Preserve the author's intent and scope — restructure for testability, don't expand
- Cite the exact plan section when flagging an issue
- Don't rewrite the plan unless there are concrete issues
