---
description: Mechanics for stacked branches — non-obvious wt and git behaviours
alwaysApply: true
---

# Branch Stacking Mechanics

For multi-step work with a forced sequence, stack branches (`main → piece-1 → piece-2`) so each PR targets its parent and shows one concern. These mechanics are not inferable:

- **Create with `-b <parent>` explicitly:** `wt switch -c piece-2 -b piece-1 --yes`. Without `-b`, `wt` forks off the repo's default branch regardless of which worktree you are in — the current branch is *not* inferred. Verify with `git merge-base piece-2 piece-1` and confirm it equals piece-1's tip.
- **Restack by rebasing, never by merging the parent in.** `git rebase` drops merge commits and replays only the linear commits underneath, so conflict resolutions captured in a merge commit vanish and the conflicts resurface. A stacked branch containing a merge commit is effectively stuck.
- **Rebase from the top of the stack.** With `rebase.updateRefs = true` (global config — verify once), one rebase rewrites every stacked branch pointer in lockstep. Then `git push --force-with-lease` per branch.
- **Every lower worktree must be clean before the rebase.** Afterwards, `cd` into each stale worktree and `git reset --hard` to snap it to the updated pointer.
- **Never stash *after* a rebase to rescue edits.** The stash captures "undo-rebase + your edits" as one diff, so `stash pop` regresses the worktree to its pre-rebase state.
- **PRs:** `gh pr create --base <parent> --head <branch>`. There is no built-in "push the whole stack." When the bottom PR merges, GitHub auto-retargets the next one.
