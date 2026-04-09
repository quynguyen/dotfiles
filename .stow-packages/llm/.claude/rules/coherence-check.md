---
description: Verify structural, directional, and epistemic coherence after changes
alwaysApply: true
---

# Coherence Check

After completing a set of changes (fixes, implementation steps, plan sections), run three passes:

## Structural coherence (does it hold together?)

- **Sequential** — Does each part build correctly on what came before? Does step N depend only on steps 1..N-1?
- **Holistic** — Do all parts work together without contradiction?
- **Conflict detection** — Does any change undermine, break, or regress another?
- **Completeness** — Is anything missing that would leave the codebase in an inconsistent state?

## Directional coherence (is it aimed at the right thing?)

- **Misalignment check** — Did I answer the question that was asked, or a different question that was easier to answer? The output may be internally consistent but aimed at the wrong target.
- **Recovery check** — If I caught an error mid-work, did I acknowledge and redirect transparently, or did I quietly patch around it?

## Epistemic coherence (am I honest about what I don't know?)

- **Masking check** — Am I confident because I have evidence, or because the output sounds good? Fluency is not correctness. If I lack knowledge, say so rather than producing fluent nonsense.
- **Verification check** — Did I verify before committing, or did I skip the sanity check? Unverified confidence is how blunders ship.

If any check fails, resolve it before marking work as complete.

Scale all three passes to the scope of work — a single-line fix needs a glance, a multi-file feature needs a thorough pass. Structural coherence always applies. Directional and epistemic checks matter most on ambiguous tasks, multi-step plans, and unfamiliar domains.
