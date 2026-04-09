---
description: Always use red-green TDD when writing or modifying code
alwaysApply: true
---

# TDD Discipline

When writing or modifying code, always follow aggressive red-green TDD:

1. **Red** — Write a failing test that expresses the requirement or reproduces the issue
2. **Green** — Write the minimal code to make the test pass
3. **Refactor** — Clean up while keeping tests green

Apply these skills throughout:
- `unit-testing-principles` — tests should verify behavior, not implementation. Mocks used appropriately. Tests should survive refactoring.
- `api-design-principles` — enforce separation of essential vs incidental data in function signatures, interfaces, and API contracts. Keep cross-cutting concerns out of signatures.

Never skip the red phase. Never write implementation code without a corresponding test.
