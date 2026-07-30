---
repo: ~/projects/some-repo/wt-main
verify: bun run verify
---

Describe the task the way you would describe it to a capable colleague: what you
want, the guardrails, and the exit criterion. No step-by-step instructions —
those bias the comparison toward whichever config nags hardest about process,
which is exactly the thing under test.

The verify command in the frontmatter is the score. It runs in a disposable
worktree after the agent stops, and its exit code decides pass or fail. If a task
has no mechanical pass/fail, it does not belong in the corpus.

## What makes a good corpus task

Real work you actually wanted done, not a puzzle. The point is to measure the
config against the kind of thing you use it for.

Hard enough that the outcome is genuinely uncertain. A task every config passes
tells you nothing, and neither does one every config fails.

Self-verifying. The agent needs a way to know it is done — tests, a typecheck, a
build — or you are measuring luck.

Bounded. Something that runs for hours makes the matrix unaffordable. Aim for
work that finishes in ten or twenty minutes.

Three to five tasks is enough. The corpus saturates as models improve, so expect
to replace it every few generations rather than growing it forever.
