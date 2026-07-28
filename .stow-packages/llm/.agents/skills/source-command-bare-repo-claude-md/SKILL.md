---
name: "source-command-bare-repo-claude-md"
description: "Generate a AGENTS.md for the root of a bare git repo that orients Codex to the worktree layout"
---

# source-command-bare-repo-claude-md

Use this skill when the user asks to run the migrated source command `bare-repo-claude-md`.

## Command Template

# /bare-repo-Codex-md

## Purpose

When Codex launches from a bare git repo root, it finds no source files and no project AGENTS.md. This command generates a root-level AGENTS.md that orients Codex: what this directory is, where the code lives, what can and can't be done from here, and where to find the real project instructions.

The generated file is untracked (bare repos have no working tree to commit from), so it won't conflict with any branch's AGENTS.md.

## Contract

**Inputs:** None required. Discovers everything from git state.
**Outputs:** `AGENTS.md` written to the current directory (the bare repo root).

## Instructions

1. **Verify this is a bare git repo:**
   ```bash
   git rev-parse --is-bare-repository
   ```
   If not `true`, stop and tell the user this command is meant for bare repo roots.

2. **Discover worktrees:**
   ```bash
   git worktree list
   ```
   Parse the output to get each worktree's path, commit, and branch name.

3. **Identify the main worktree:**
   Find the worktree on `main` or `master` branch. This is the canonical worktree — the one users mean when they say "the code" without specifying a branch.

4. **Check for a project AGENTS.md:**
   Look for `AGENTS.md` in the main worktree. If it exists, the generated file should reference it. If it doesn't, note that no project AGENTS.md was found.

5. **List worktrees:**
   Note each non-main worktree's directory name and branch. In the generated directory tree, show `wt-main/` as the canonical entry and `wt-[branch-name]/` as a single generic placeholder for all other worktrees — don't categorize or group by prefix.

6. **Check for a worktree CLI (`wt`):**
   ```bash
   command -v wt
   ```
   If `wt` is available, include worktree lifecycle commands in the output. If not, omit that section — don't assume tooling the user doesn't have.

7. **Generate `AGENTS.md`** with these sections:

   - **Header** — State this is a bare git repo with no working tree. All code lives in `wt-*/` worktrees.
   - **Directory tree** — Show `wt-main/` (or whatever the main worktree is named) as the canonical entry, then `wt-[branch-name]/` as a generic placeholder for parallel worktrees.
   - **Critical rules** — Three rules that prevent the most common mistakes:
     1. Never run project commands (`bun`, `npm`, `prisma`, test runners, dev scripts) from this directory — always `cd` into a worktree first.
     2. The project AGENTS.md is at `<main-worktree>/AGENTS.md` — read it before doing project work.
     3. Default to the main worktree when the user says "the code" without specifying a branch.
   - **What you can do from here** — Git commands, cross-worktree reads, orchestration, dispatching subagents.
   - **Worktree commands** (only if `wt` CLI exists) — Create and merge commands, with the rule to always run from inside a worktree.

8. **Write the file** to the current directory as `AGENTS.md`. If one already exists, show the user a diff of what would change and ask before overwriting.

## Constraints

- Everything is discovered from git state — nothing is hardcoded to a specific project
- The generated file should work for any bare repo, not just this one
- Keep the output concise — this is orientation, not documentation
