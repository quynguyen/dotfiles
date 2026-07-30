---
description: Fix issues with TDD discipline and coherence verification
argument-hint: [file-path-or-description]
---

# /fix-issues

## Purpose

Fix issues using TDD discipline, then verify the work is coherent.

## Contract

**Inputs:** `$ARGUMENTS` — (optional) one of:
- A path to a file containing issues (e.g., review feedback, bug report)
- A text description of the issues to fix
- If empty, assume the issues are known from the current conversation context

**Outputs:** Fixed code with passing tests and a coherence check

## Instructions

1. **Identify the issues:**
   - If `$ARGUMENTS` is a readable file path, read it for the list of issues
   - If `$ARGUMENTS` is text, treat it as the issue description
   - If `$ARGUMENTS` is empty, use the issues already discussed in the current conversation context
   - If no issues can be identified, ask the user to clarify

2. **Fix each issue** following TDD discipline as applicable.
   Fix in a logical order where dependencies exist.

3. **Verify:** typecheck, tests, and lint must pass — not done until green. Then confirm no change undermines another, and that nothing is left in an inconsistent state.

## Constraints

- Keep fixes focused — don't expand scope beyond the identified issues
