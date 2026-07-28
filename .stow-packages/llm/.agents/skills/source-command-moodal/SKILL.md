---
name: "source-command-moodal"
description: "Maslow OODA Loop — review priorities, gather context, re-score, decide what to work on"
---

# source-command-moodal

Use this skill when the user asks to run the migrated source command `moodal`.

## Command Template

# /moodal

Run the Maslow OODA Loop for the current project.

## Steps

1. **Check for `docs/priorities.md`**. If it doesn't exist, ask the user if they want to create one.

2. **Observe** — gather context automatically:
   - Read `docs/priorities.md`
   - Run `git log --oneline -20` to see what shipped since the "Last reviewed" date
   - Check the Maslow's Inbox (minbox) for unsorted demand signals
   - Scan the current conversation for uncaptured signals (frustrations, wishes, broken things mentioned but not recorded)

3. **Present state** — show a concise summary:
   - What shipped since last review (move to Completed)
   - Current minbox entries (if any)
   - Current Active #1-3 with scores
   - Any newly captured signals from this session

4. **Orient** — ask if re-scoring is needed:
   - If yes: for each candidate, explain *how* it limits progress, then re-rank
   - If no: confirm current #1

5. **Decide** — confirm what to work on next

6. **Update** — write changes to `docs/priorities.md`:
   - Update "Last reviewed" date
   - Move shipped items to Completed
   - Triage minbox items into Active/Queued
   - Update scores if re-scored

Keep the interaction tight. Don't over-explain — present data, ask for decisions.
