---
description: Use wt commands for all worktree operations — never raw git worktree commands
alwaysApply: true
---

# Worktree Lifecycle

Use `wt` for all worktree operations:

- **Create:** `wt switch -c <branch> --yes` from inside a worktree (e.g., `wt-main/`), never from the bare repo root
- **Merge:** `wt merge --yes` to merge, remove worktree, and delete branch in one step — don't manually `git merge` + `git worktree remove` + `git branch -d`

Always pass `--yes` to `wt` commands. Claude Code runs non-interactively and cannot approve hook prompts. Without `--yes`, post-create and pre-merge hooks fail silently.

Running `wt` from the bare repo root causes post-create hooks (`wt step copy-ignored`, `bun install`, `bunx prisma generate`, `bun migrate.js`) to not execute, silently leaving the worktree without `.env.local`, the database, or pending migrations.

Always `cd` into a worktree (e.g., `wt-main/`) before running `wt switch`. When done with a branch, use `wt merge --yes`.
