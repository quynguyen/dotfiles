---
description: Fix broken windows immediately — warnings, dead code, and mechanical noise don't survive the session
alwaysApply: true
---

# No Broken Windows

The Pragmatic Programmer's "broken windows" principle: one unfixed problem signals that nobody cares, which invites more neglect. A codebase with 12 lint warnings will soon have 30. A test suite with one skipped test will soon have ten. Entropy accelerates once standards visibly slip.

LLMs flipped the economics. Fixing a broken window used to cost 20 minutes of human investigation — often not worth it. Now it costs ~30 seconds of agent time. But the cost of *leaving* it compounds on every future session: thousands of tokens spent parsing, reasoning about, and dismissing the same noise. And unfixed warnings mask new ones — the 13th warning that actually matters gets buried in the 12 you've been ignoring.

**The rule:** When you encounter broken windows — fix them in the same session. Don't ask whether to skip them. Don't defer them as "pre-existing."

**This includes:** lint warnings, unused imports, dead variables, stale TODO comments, commented-out code, unused eslint-disable directives, skipped tests, inconsistent formatting, and any other mechanical decay in code or tool output.

**Exception:** Load-bearing decisions — issues where the "fix" has non-obvious consequences or requires tradeoffs that only a human can evaluate. Examples: upgrading a deprecated dependency (may break downstream consumers), resolving a design tension flag (choosing between competing architectural goals), or changing vendored code you don't own (upstream may overwrite it). The distinction: a broken window has a mechanically correct fix; a load-bearing decision has multiple valid fixes with different costs. Flag these to the user instead of acting.
