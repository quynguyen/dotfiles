---
description: Implement a plan using TDD with worktree isolation
argument-hint: <plan-file-or-path>
---

# /implement-plan

## Purpose

Implement a plan using TDD discipline, with work isolated in git worktrees.

## Contract

**Inputs:** `$ARGUMENTS` — path to the plan/spec file to implement
**Outputs:** Implemented features across worktrees following TDD discipline

## Instructions

1. **Validate inputs:**
   - Check that `$ARGUMENTS` points to a readable plan file
   - If no file is provided, ask the user which plan to implement

2. **Read and analyze the plan:**
   - Read the full plan file
   - Break the work into independent, parallelizable chunks suitable for worktree isolation

3. **Set up worktrees:**
   - Use `wt` (worktrunk) to create isolated worktrees for each chunk of work
   - Each worktree should represent a logical unit that can be developed and tested independently

4. **Implement each chunk** following TDD discipline and frontend skills rules as applicable.
   - Implement in the sequence defined by the plan
   - Ensure each step's tests pass before moving to the next
   - Keep worktree branches focused — one logical concern per branch

5. **Run the coherence check** across the full implementation per the coherence-check rule.

## Constraints

- Preserve the plan's scope — implement what's specified, don't expand
- Each worktree branch should be mergeable independently where possible
