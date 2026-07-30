# ablate — what to do when a new model ships

A new frontier model arrives every two or three months, and each one re-opens the
same question: which of these instructions still earn their place, and which are
now dead weight or active interference? Answering by judgment costs hours and
produces a guess. This makes it mechanical.

## The idea that makes it cheap

Sort the config into three piles **once**:

**Facts** are things about this machine that no model can derive. `wt` fails
silently without `--yes`. Running it from the bare repo root skips post-create
hooks. `rebase.updateRefs` must be set globally. These never need retesting —
they are not claims about the model.

**Taste** is preference rather than correctness: TDD, prose over labelled
bullets, progress files only in feature worktrees. A better model does not
converge on these, because they are not facts about the world. Also never needs
retesting.

**Supervision** exists to stop an older model over-engineering, skipping
verification, or acting without asking. This is the only pile that is
model-dependent, and it should shrink toward empty over successive releases.

That is the whole trick. Classifying honestly once turns an O(all-rules) problem
per release into O(supervision-rules) per release.

## The procedure

**1. Snapshot the current config before touching anything.**

```sh
git -C ~/dotfiles tag pre-<model>-reset
ablate profile pre-<model> --source pre-<model>-reset
```

**2. Measure the floor.** This is step one, not step three — the 2026-07-30 reset
skipped it and destroyed its own baseline.

```sh
ablate baseline live
```

**3. Strip the supervision pile**, keeping facts and taste untouched. Commit it.

**4. Measure again and compare.**

```sh
ablate baseline live pre-<model>
```

**5. Run the task corpus** if the corpus exists (see `tasks/`).

```sh
ablate run --profiles live pre-<model> --reps 3 --yes
```

**6. Log what happened** in `results/` and in `../stumble-log.md`. Anything a
stripped rule would have prevented, seen twice, earns that rule back — in the
fewest words that fix it.

## Constraints worth knowing before you start

**A fresh profile cannot authenticate.** Claude Code will not bootstrap an OAuth
session into a new `CLAUDE_CONFIG_DIR`. A fresh one reports "Not logged in";
copying `~/.claude.json` in gives "OAuth session expired and could not be
refreshed", because the copy's session cannot refresh; seeding `oauthAccount`,
`userID` and `machineID` is not enough either. Either run `claude` interactively
inside the profile once and log in, or use the profile named `live`, which leaves
`CLAUDE_CONFIG_DIR` unset and measures the real config. **Comparing `live`
against one already-bootstrapped snapshot is the practical path.**

**Never measure from `$HOME`.** Claude Code reads `~/.claude/settings.json` a
second time as *project* settings there, dragging in its allow list and
triggering the workspace-trust dialog, which hangs a headless run forever.
`ablate` uses a neutral empty directory for this reason.

**`~/dotfiles/.gitignore` has a bare `CLAUDE.md` rule.** The global `CLAUDE.md`
was therefore untracked for the whole history up to 2026-07-30, so no tag before
that contains it and `pre-opus5-reset` is incomplete. A negation now tracks it.
`archive/<ref>/` holds recovered copies for older refs, and `ablate profile`
falls back to that automatically.

**Pass rate is the only score that means much.** Cost, turns and wall time are
tiebreakers. None of them say whether the code is any good — read the diffs
before concluding a profile won.

**Runs cost money.** `ablate run` refuses without `--yes` and prints an estimate
first. A 3-task × 2-profile × 3-rep matrix is 18 agent runs.

## Results so far

**2026-07-30, Opus 5.** Original config 35,738 context tokens per request;
stripped config 27,950. The strip removed 7,788 tokens from the floor of every
request, 22% of the original. `CLAUDE.md` went 77 → 11 lines, eight rules files
became three, five plugins were disabled.

That number says nothing about whether output quality changed — only that the
tax fell. The corpus is what would answer the quality question, and it does not
exist yet.
