---
name: qmd
description: |
  Local search engine over the user's markdown documents (5570+ docs across notes, logseq, shopify-backup collections). Use when the user references their notes, journals, past writing, or asks to find something they wrote. Triggers on: "find my note about", "what did I write about", searching personal knowledge base, retrieving journal entries.
---

# qmd — Local Knowledge Base Search

CLI already installed. Searches across collections: notes (4820 docs), logseq (656 docs), shopify-backup (94 docs).

## Commands

```bash
# Recommended: query expansion + reranking (best results)
qmd query <query>

# Keyword search (BM25, fast, ~30ms)
qmd search <query>

# Vector similarity search (meaning-based, ~2s)
qmd vsearch <query>

# Retrieve a specific document
qmd get <file>              # full doc
qmd get <file>:100 -l 50   # from line 100, 50 lines

# Batch retrieve by glob or list
qmd multi-get "journals/2025-05*.md"
```

## Useful flags

```bash
-n 10                  # number of results (default: 5)
-c notes               # filter to collection
--min-score 0.5        # filter low-confidence results
--full                 # output full document, not snippet
--files                # output file paths only (default: 20)
--json                 # JSON output with snippets
--no-rerank            # skip reranking in `query` (faster, less precise)
```

## Examples

```bash
qmd query "prisma driver adapter"
qmd search "meeting notes Q1" -c notes
qmd vsearch "token optimization strategies"
qmd get journals/2025-04-01.md
```

## When to use

- User references their own notes, journals, or past writing
- Searching for something the user wrote before
- Finding context from the user's knowledge base

## When NOT to use

- Searching the current project codebase (use Grep/Glob)
- Looking up library docs (use `context7`)
- Understanding GitHub repos (use `deepwiki`)
