---
name: context7
description: |
  Fetch current library/framework documentation via CLI. Use when the user asks about a library, framework, SDK, API, or CLI tool — even well-known ones like React, Next.js, Prisma, Tailwind. Prefer over web search for library docs. Triggers on: API syntax, configuration, version migration, library-specific debugging, setup instructions, CLI tool usage.
---

# context7 — Library Documentation Lookup

CLI at `~/.bin/context7`. Wraps the Context7 API.

## Commands

```bash
# One-step: resolve library + query docs
context7 search <library> <query>

# Two-step: resolve first, then query with exact ID
context7 resolve <library>
context7 query <libraryId> <query>
```

## Examples

```bash
context7 search "next.js" "app router middleware"
context7 search prisma "client api findMany"
context7 search tailwind "dark mode configuration"
context7 resolve react
context7 query /facebook/react "useEffect cleanup"
```

## When to use

- User asks about library API, config, or usage
- You need current docs (your training data may be stale)
- Version-specific questions (pass version in query)

## When NOT to use

- Refactoring, writing scripts from scratch, debugging business logic
- Code review or general programming concepts
