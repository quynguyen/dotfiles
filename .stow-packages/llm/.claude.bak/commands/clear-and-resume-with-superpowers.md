---
description: Save progress and generate a resume prompt before clearing context
argument-hint: [plan-file-path]
---

# /clear-and-resume-with-superpowers

## Purpose

Save current progress to a `progress.md` file, then generate a copy-paste prompt the user can type after clearing context to resume work seamlessly.

## Contract

**Inputs:** `$ARGUMENTS` — (optional) path to the plan file. If not provided, use the most recent plan discussed in the current conversation context.
**Outputs:** A `progress.md` file and a ready-to-paste resume prompt

## Instructions

1. **Locate the plan:**
   - If `$ARGUMENTS` is provided and points to a readable file, use that as the plan
   - Otherwise, identify the plan from the current conversation context (the most recently discussed or actively worked-on plan)
   - If no plan can be identified, ask the user to clarify

2. **Assess current progress:**
   - Read the plan (from file or conversation context)
   - Review the current state of the codebase, recent changes, and any active worktrees
   - Determine which plan steps are complete, in progress, and remaining

3. **Write the progress file:**
   - Name it after the plan file with a `-progress` suffix: e.g., `plan.md` → `plan-progress.md`, `auth-spec.md` → `auth-spec-progress.md`
   - **Placement rule — avoid worktree merge conflicts:**
     - If in a **feature worktree**: write the progress file alongside the plan file *within the feature worktree's copy*. It will merge back to wt-main with the PR, landing next to the plan for posterity.
     - If in **wt-main** with no feature worktree active: write alongside the plan file. This is safe because no feature branch exists yet to conflict with.
     - **Never create or update a progress file in wt-main while a feature worktree is active** — this causes merge conflicts when the PR lands.
   - If the plan was only in conversation context, write the plan itself to a file first, then write the progress file per the placement rule above
   - Structure it as:

   ```markdown
   # Progress

   **Plan:** <plan filename or description>
   **Updated:** <current date>

   ## Completed
   - <step/task that is done>

   ## In Progress
   - <step/task currently underway, with notes on state>

   ## Remaining
   - <step/task not yet started>

   ## Notes
   - <any context the next session needs: blockers, decisions made, gotchas>
   ```

4. **Generate the resume prompt:**
   - Output a fenced code block the user can copy-paste after clearing context
   - The prompt must reference:
     - The `superpowers` skill (use `executing-plans`)
     - The plan file path (now guaranteed to exist as a file)
     - The progress file path
     - **Worktree progress file rule** — the next session must know to only update the progress file in the feature worktree, never in wt-main
     - Instructions to apply skills conditionally:
       - Logic/code structure changes → `unit-testing-principles`, `api-design-principles`
       - Frontend/UI changes → `vercel-react-best-practices`, `vercel-composition-patterns`, `interface-design`
     - Use `wt` (worktrunk) for worktree isolation

   Example output:

   ````
   ```
   Resume implementation using the `superpowers:executing-plans` skill.

   Plan: <path/to/plan.md>
   Progress: <path/to/progress.md>

   Continue from where we left off per progress.md. Implement using an aggressive red-green TDD approach.

   IMPORTANT — worktree progress file rule:
   The progress file is an implementation artifact. Only read/update it in the
   feature worktree, never in wt-main. It will merge back alongside the plan
   when the PR lands.

   Apply these skills for logic and code structure changes:
   - unit-testing-principles
   - api-design-principles

   If frontend or UI work is needed, apply these skills:
   - vercel-react-best-practices
   - vercel-composition-patterns
   - interface-design

   Use `wt` (worktrunk) to isolate work in worktrees.
   ```
   ````

5. **Confirm to the user:**
   - Show where `progress.md` was written
   - Show the resume prompt in a copyable block
   - Tell them they can now clear context and paste the prompt

## Constraints

- Never clear the context yourself — only prepare for the user to do it
- Be accurate about what's done vs in progress — check actual file state, not assumptions
- Keep `progress.md` concise — it's a handoff document, not a narrative
- If the plan only existed in conversation, persist it to a file so the next session can read it
