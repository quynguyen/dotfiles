---
description: Study Chrome DevTools traces (cold + warm) and formulate a spec and plan to improve the app
argument-hint: [page-url-or-screenshot]
---

# /chrome-trace-study-and-improve

## Purpose

Analyze Chrome DevTools performance traces (cold and warm) alongside a page URL or screenshot, then produce a spec and implementation plan for improvements — applying the right skills based on the type of changes identified.

## Contract

**Inputs:**
- `$ARGUMENTS` — (optional) page URL, file path, or screenshot reference. If not provided, ask the user.
- Two Chrome DevTools trace files provided by the user: one cold load, one warm load.

**Outputs:** A spec file and a plan file written to disk.

## Instructions

1. **Gather inputs:**
   - If `$ARGUMENTS` is provided, use it as the page URL/path or screenshot
   - If not provided, ask the user for the page URL/path or screenshot
   - Ask the user for the two trace files (cold and warm) if not already provided in conversation context
   - Read the page URL or screenshot to understand what the page does and looks like

2. **Study the traces:**
   Analyze both traces systematically:
   - **Cold trace** (first visit, empty cache): focus on initial load performance, resource loading waterfall, blocking resources, time to first byte, largest contentful paint, total blocking time, cumulative layout shift
   - **Warm trace** (repeat visit, cached): focus on cache hit rates, service worker behavior, conditional requests, delta between cold and warm metrics
   - **Compare cold vs warm**: identify what improves with caching and what doesn't — the persistent bottlenecks are the most important findings
   - Identify: long tasks, layout thrashing, excessive reflows, render-blocking resources, unused JavaScript, slow network requests, memory leaks, unnecessary re-renders

3. **Categorize findings:**
   Sort each finding into one or both categories:
   - **Logic/code structure changes** — backend optimization, data fetching, caching strategy, code splitting, API design, computation efficiency
   - **Frontend/UI changes** — rendering performance, component architecture, layout optimization, animation performance, visual regressions

4. **Write the spec:**
   Invoke the `write-spec` skill mindset, applying these skills based on categories:

   For logic and code structure changes:
   - `unit-testing-principles` — structure every requirement so it maps to testable units with clear red-green boundaries
   - `api-design-principles` — enforce separation of essential vs incidental data, keep cross-cutting concerns out of signatures

   For frontend/UI changes:
   - `vercel-react-best-practices` — performance patterns, data fetching strategy, bundle optimization
   - `vercel-composition-patterns` — composition over configuration, compound components, avoid boolean prop proliferation
   - `frontend-design` — craft, consistency, design system alignment

   Each spec item must:
   - Reference the specific trace evidence (e.g., "Long task at 2.3s blocking main thread for 180ms")
   - Quantify the expected improvement where possible
   - Be precise enough to write a failing test against

5. **Write the plan:**
   Invoke the `write-plan` skill mindset with the same skill applications from step 4.

   For each task:
   - Define the expected behavior precisely enough to write assertions against
   - Order steps so tests can be written incrementally (red-green-refactor)
   - Break work into independent chunks suitable for worktree isolation
   - Specify which chunks can be parallelized and which have sequential dependencies

6. **Coherence check:**
   Do one final pass across both the spec and the plan together:
   - Is the work sequentially logical? (Does step N depend only on steps 1..N-1?)
   - Are there contradictions between the spec and the plan?
   - Do the TDD suggestions conflict with the frontend/design suggestions?
   - Do performance optimizations conflict with each other? (e.g., code splitting vs reducing request count)
   - Is the scope internally consistent — no requirements that undermine each other?
   - Does the plan fully cover the spec? Are there spec items with no corresponding plan task?
   - Flag and resolve any conflicts before finalizing

7. **Write files:**
   - Save spec and plan to a sensible location (project root or `plans/` directory if one exists)
   - Name them descriptively: e.g., `spec-dashboard-perf.md`, `plan-dashboard-perf.md`
   - Tell the user where the files were written and summarize the key findings

## Constraints

- Every improvement must be backed by trace evidence — no speculative optimizations
- Every task must be testable — if it can't be expressed as a failing test, rewrite it until it can
- Keep scope to what the traces reveal — don't expand into unrelated improvements
- Be specific: vague tasks like "improve performance" must be quantified with trace metrics
- Prioritize by impact: order improvements by expected performance gain, largest first
