---
description: Review recent changes for TDD principles, design quality, and coherence
argument-hint: [commit|branch|worktree]
---

# /rev-changes

## Purpose

Review recent changes, applying TDD and design rules, then verify coherence.

## Contract

**Inputs:** `$ARGUMENTS` — (optional) scope of changes to review:
  - `commit` — the most recent commit
  - `branch` or a branch name — all changes introduced by the branch
  - `worktree` or a worktree path — all changes in the worktree
  - If not provided, review uncommitted work in progress (staged + unstaged)
**Outputs:** A structured review of the changes

## Instructions

1. **Determine scope:**
   - `commit` or SHA → `git diff <commit>~1..<commit>`
   - `branch` or name → `git diff main...<branch>`
   - `worktree` or path → review changes in that worktree
   - No arguments → `git diff` + `git diff --cached` for WIP

2. **Read the changes:**
   - Get the full diff
   - Read changed files to understand context beyond the diff

3. **Review** applying TDD discipline as applicable:
   - Are tests present? Do they test behavior, not implementation?
   - Are API boundaries clean?
   - Are frontend patterns correct? (if UI changes present)

4. **Verify:** typecheck, tests, and lint must pass — not done until green. Then confirm no change undermines another, and that nothing is left in an inconsistent state.

5. **Output:**
   - **Scope** — what was reviewed
   - **Findings** — test quality, API cleanliness, frontend patterns (as applicable)
   - **Coherence** — conflicts, gaps, or inconsistencies
   - **Recommendations** — specific, actionable items

## Constraints

- Review what's there, don't suggest scope expansion
- Be specific: reference file paths and line numbers
- Distinguish between blocking issues and suggestions
