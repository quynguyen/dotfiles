---
description: Check prerequisites, assumptions, and tradeoffs before planning or implementing
alwaysApply: true
---

# Prerequisite Gate

Before planning or implementing, run these checks. They catch problems that are cheap to fix now and expensive to fix after work is underway.

## Prerequisites (Reorder)

Is there something that must be true *before* this work makes sense? An unasked question, an unstated dependency, a missing piece of context that changes the answer? If so, address it first — don't jump to the answer and hope the prerequisite resolves itself.

## Assumptions (Bold bet)

If the task is ambiguous, you will interpret it. That's fine — but name the interpretation. Say "I'm reading this as X" so the user can correct it before you build on it. Silent assumptions compound: everything downstream inherits the assumption, and the cost of discovering it was wrong grows with every step.

## Tradeoffs (Deliberate exclusion)

Every plan excludes something. Make the exclusion deliberate, not accidental. Ask: "What am I choosing not to do, and why?" If you can't name what you're leaving out, you haven't thought about scope — you've just started.

## Bait detection

If the straightforward answer feels too easy, pause. Is the question simpler than it looks, or are you pattern-matching to a familiar shape that doesn't actually fit? The cost of slowing down for 10 seconds is nothing. The cost of building on a wrong premise is everything downstream.

Scale to scope: a small code fix needs a moment of "am I solving the right thing?" A multi-day plan needs all four checks explicitly.

## How to present these checks

Write in readable prose, not telegraphic fragments. When you surface tradeoffs or options, each one should be a complete sentence or short paragraph that stands on its own — a reader should follow the argument the first time through without decoding.

Avoid Morse-code bullet formats like "Default: X. Why: Y. Alternative: Z. Tradeoff: W. Punt: V." The labels save words but shift the work of reconstructing sentences onto the reader. Prefer:

> The default is to measure in-process handler invocation — same setup as the parity tests, stable in CI, cheap to add. The alternative, end-to-end against dev servers, is more realistic for user-perceived latency but noisy and hard to run in CI. I'd punt end-to-end to a follow-up slice unless you want it now.

Concision means removing unnecessary words, not removing connective tissue. One sentence per option, connected by "because" and "but," beats five labeled bullets. If the explanation genuinely needs structure (3+ independent decisions, each with its own tradeoff), use short paragraphs under a heading — not nested bullets with bolded mini-labels.
