---
name: deepwiki
description: |
  AI-powered documentation for GitHub repositories. Use when the user asks about how a specific GitHub repo works, its architecture, patterns, or internals. Triggers on: "how does X repo work", understanding open-source project internals, comparing repos, repo-level architecture questions.
---

# deepwiki — Repository Documentation

CLI at `~/.bin/deepwiki`. Wraps the DeepWiki API.

## Commands

```bash
# List documentation topics for a repo
deepwiki topics <owner/repo>

# Get full repository documentation
deepwiki docs <owner/repo>

# Ask a question about a repo (or multiple repos, comma-separated, max 10)
deepwiki ask <owner/repo> <question>
deepwiki ask <repo1,repo2> <question>
```

## Examples

```bash
deepwiki topics prisma/prisma
deepwiki ask vercel/next.js "how does the app router work?"
deepwiki ask prisma/prisma,drizzle-team/drizzle-orm "compare query builder patterns"
```

## When to use

- Understanding how an open-source project works internally
- Comparing architectures across repos
- Finding patterns or conventions in a specific repo

## When NOT to use

- Looking up API/SDK usage docs (use `context7` instead)
- Searching your own local codebase (use `qmd` or Grep)
