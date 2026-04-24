---
description: Prefer stacked branches for multi-step work with a forced sequence
alwaysApply: true
---

# Branch Stacking

When work splits into multiple pieces that each ship independently and have a forced sequence (piece 2 needs piece 1), use a **stack** of branches — not one big branch, and not unrelated branches off main.

```
main → piece-1 → piece-2 → piece-3
```

Each branch targets its parent in the PR, so each diff shows one concern. When piece-1 merges, piece-2 auto-retargets main — the stack shrinks from the bottom.

## Why not the alternatives

- **One big branch.** Reviewers skim 2,000-line diffs; you can't ship partial progress while one piece is contested; merge conflicts compound daily.
- **Several unrelated branches off main.** Fine when pieces are truly independent. But if piece 2 depends on piece 1's code, branching both off main means piece 2's diff also contains piece 1's changes — reviewers see noise, and you'll hit phantom conflicts when piece 1 merges.

## When NOT to stack

- Single atomic change → one branch.
- Truly independent changes (no shared code) → parallel branches off main.
- Exploratory spike where the shape isn't settled → don't stack until you know the pieces.

## Mechanics

- **Create each branch with `-b <parent>` explicitly.** `wt switch -c piece-2 -b piece-1 --yes`. Without `-b`, `wt` forks the new branch off the repo's default branch (main) regardless of which worktree you're currently in — the current worktree's branch is *not* inferred. After creating, verify with `git merge-base piece-2 piece-1` and confirm the result equals piece-1's tip, not main's.
- **Keep stacked branches linear.** When a lower branch changes, restack higher branches by rebasing them onto it, not by merging the lower branch into them. Merges are hostile to future restacks: `git rebase` drops merge commits by default and replays only the linear commits underneath, so any conflict resolution captured in a merge commit disappears and the original conflicts resurface. Once a stacked branch contains a merge commit, it's effectively stuck — you can only keep restacking it via further merges.
- **Push and open PRs per branch.** `git push -u origin <branch>`, then `gh pr create --base <parent> --head <branch>`. The bottom PR targets `main`; each one above targets the branch below. No built-in "push the whole stack."
- **Amend lower branches by rebasing from the top of the stack.** With `rebase.updateRefs = true` (global git config — verify once), one rebase from the top rewrites every stacked branch pointer in lockstep. Then `git push --force-with-lease` per affected branch.
- **Every lower worktree must be clean before the rebase.** Commit or stash in each one first. After the rebase, `cd` into each stale worktree and `git reset --hard` to snap its files to the updated pointer.
- **Do not stash *after* a rebase to rescue edits.** The stash captures "undo-rebase + your edits" as one diff, so `stash pop` regresses the worktree back to the pre-rebase state. Keep worktrees clean going in.
- **When the bottom PR merges**, GitHub auto-retargets the next PR to `main`. Tear down the merged branch with `wt merge --yes` from its parent worktree.
