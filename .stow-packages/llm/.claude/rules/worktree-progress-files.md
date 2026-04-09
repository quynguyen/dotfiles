---
description: Progress files are implementation artifacts — only create/update in feature worktrees
alwaysApply: true
---

# Worktree Progress File Rule

Progress files (e.g., `*-progress.md`) are implementation artifacts, not planning artifacts.

- If in a **feature worktree**: write/update the progress file within the feature worktree's copy of the plan directory. It will merge back to wt-main with the PR, landing next to the plan for posterity.
- If in **wt-main** with no feature worktree active: writing alongside the plan is safe since no feature branch exists to conflict with.
- **Never create or update a progress file in wt-main while a feature worktree is active** — this causes merge conflicts when the PR lands.

Planning artifacts (specs, audits, plans) → wt-main.
Progress files → feature worktree only.
