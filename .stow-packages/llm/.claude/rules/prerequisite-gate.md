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
