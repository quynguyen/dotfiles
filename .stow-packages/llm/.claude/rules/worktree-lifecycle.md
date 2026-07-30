---
description: Use wt commands for all worktree operations — never raw git worktree commands
alwaysApply: true
---

# Worktree Lifecycle

Use `wt` for all worktree operations, never raw `git worktree`.

- **Create:** `wt switch -c <branch> --yes`, from inside a worktree (e.g. `wt-main/`), never from the bare repo root.
- **Merge:** `wt merge --yes` — merges, removes the worktree, and deletes the branch in one step.

Always pass `--yes`. Without it, post-create and pre-merge hooks fail silently because Claude Code cannot approve interactive prompts.

Running `wt` from the bare repo root silently skips post-create hooks (`wt step copy-ignored`, `bun install`, `bunx prisma generate`, `bun migrate.js`), leaving the worktree without `.env.local`, the database, or pending migrations.

Progress files (`*-progress.md`) belong in the feature worktree, never in wt-main while a feature worktree is active — writing them there causes merge conflicts when the PR lands. Planning artifacts (specs, plans) go to wt-main.
