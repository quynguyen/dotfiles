---
name: epiphany
description: |
  Capture an engineering epiphany mid-session with near-zero friction. Extracts a
  reusable principle from the current problem you're solving — AI expands your
  one-liner into a structured, publishable discovery. Saves to the epiphanies
  collection for the Astro site. Use when you say "I just realized...",
  "the insight here is...", or want to capture a principle from active work.
allowed-tools:
  - Bash
  - Read
  - Write
  - AskUserQuestion
  - Glob
  - Grep
---

# /epiphany — Capture an Engineering Discovery

You are capturing an engineering principle that the user just extracted from active work.
Your job is to preserve their insight with structure — not to generate the insight.

## Step 1: Gather the Zinger

Ask the user for their one-line principle (the "zinger") and optional context about what
problem produced it.

<tool>
AskUserQuestion with these questions:

Question 1:
  question: "What's the principle? (The one-liner — e.g., 'Fewer parts that hide problems are worse than more parts that expose them.')"
  header: "Zinger"
  options:
    - label: "I'll type it"
      description: "Type your one-line principle"
  multiSelect: false

Question 2:
  question: "What problem or situation produced this insight? (Optional — adds provenance)"
  header: "Context"
  options:
    - label: "I'll describe it"
      description: "Describe the specific case that led to this principle"
    - label: "Skip"
      description: "No additional context — use git history for provenance"
  multiSelect: false
</tool>

Save the user's answers as `ZINGER` and `CONTEXT`.

## Step 2: Gather Git Context (Supplementary)

Run these commands silently to capture provenance. If not in a git repo, skip this step.

```bash
# Current project name
basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown"

# Current branch
git branch --show-current 2>/dev/null || echo "unknown"

# Recent work context (truncate to 20 lines)
git diff --stat HEAD~1 2>/dev/null | head -20

# Recent commits
git log --oneline -5 2>/dev/null
```

Save these as `PROJECT`, `BRANCH`, `DIFF_STAT`, `RECENT_COMMITS`.

## Step 3: AI Expansion

Using the ZINGER, CONTEXT, and git context, generate a structured discovery. The user's
words are primary — your job is to add structure, not to change the insight.

Generate these sections:

1. **generalized** — A one-sentence generalized form of the zinger (for meta tags / subtitle)
2. **The Specific Case** — What problem produced this insight (from CONTEXT + git context)
3. **The Generalization** — Why this principle generalizes beyond the specific case (2-3 paragraphs max)
4. **Balances Against** — What established wisdom this principle balances against
5. **When It Applies** — 3-5 bullet points: boundary conditions where this principle holds
6. **When It Doesn't** — 3-5 bullet points: boundary conditions where the counter-principle wins
7. **tags** — 2-5 auto-generated tags for categorization

## Step 4: Confirm Counter-Principle

Before saving, confirm the "Balances Against" with the user:

<tool>
AskUserQuestion:
  question: "Does this counter-principle feel right? '[the proposed balances_against value]'"
  header: "Balance"
  options:
    - label: "Yes, that's right"
      description: "Use the proposed counter-principle"
    - label: "Not quite"
      description: "I'll provide a better counter-principle"
  multiSelect: false
</tool>

If the user selects "Not quite" or "Other", use their replacement.

## Step 5: Generate Slug and Save

Generate the slug using the date and zinger:
- Format: `YYYY-MM-DD-slugified-zinger` (lowercase, alphanumeric + hyphens, max ~100 chars)
- Strip punctuation, collapse hyphens, truncate at word boundary if needed

Create the discovery file at:
```
~/projects/epiphanies/src/content/discoveries/{slug}.md
```

Use this exact template:

```markdown
---
zinger: "{ZINGER}"
generalized: "{GENERALIZED}"
date: {YYYY-MM-DD}
slug: "{SLUG}"
origin:
  project: "{PROJECT}"
  problem: "{CONTEXT or auto-generated from git}"
  branch: "{BRANCH}"
tags: [{TAGS as comma-separated quoted strings}]
balances_against: "{BALANCES_AGAINST}"
status: draft
---

## The Specific Case

{SPECIFIC_CASE}

## The Generalization

{GENERALIZATION}

## Balances Against

{BALANCES_AGAINST_EXPANDED}

## When It Applies

{WHEN_IT_APPLIES as bullet list}

## When It Doesn't

{WHEN_IT_DOESNT as bullet list}

## Connected Principles

<!-- Left empty at capture time. Add cross-references as the collection grows. -->
```

## Step 6: Confirm Save

After writing the file, tell the user:
- The file path where it was saved
- That status is `draft` — change to `published` when ready to share
- Remind them they can edit the file directly to refine before publishing

## Constraints

- The ZINGER is the user's words — never rewrite it
- Keep total interaction under 60 seconds (2 prompts max)
- If git context is unavailable, proceed with user-provided context only
- Tags should be lowercase, hyphenated, and meaningful (not generic like "software")
- The generalized field is a one-liner for meta tags; The Generalization section is the expanded explanation
- Always save with `status: draft`
