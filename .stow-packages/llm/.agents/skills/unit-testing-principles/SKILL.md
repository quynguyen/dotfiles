---
name: unit-testing-principles
description: |
  Write unit tests that enable changeability, not just correctness. Use this skill whenever writing, reviewing, or refactoring unit tests. Triggers on: creating test files, writing test cases, setting up test doubles/mocks/stubs (Mockito, MockK, unittest.mock, Jest), choosing between verify() and return-value assertions, structuring test helpers and SUT construction, or evaluating test quality. Also use when tests are brittle and break during refactoring, when deciding between unit and integration tests, when choosing @InjectMocks vs manual construction, or when a test file has excessive when/thenReturn setup or is hard to read and maintain.
---

# Unit Testing Principles: Tests for Changeability

## Core Principle

**Unit tests exist to enable change, not to prevent bugs.**

Integration tests ensure the system behaves correctly as a whole. Unit tests ensure the system *can be changed safely* by isolating each component so that a bug in one place causes exactly one test failure — not a cascade. When unit tests break during a refactor that doesn't change behavior, the tests have failed at their primary purpose.

A good unit test makes the codebase *easier* to change. A bad unit test makes it *harder*. The difference lies in three properties: **Readability**, **Isolation**, and **Refactor-Friendliness**.

## Readability

- **Name the test for the behavior and scenario it verifies**, not the method it calls. `shouldFailWhenMemberNotFound()` tells a developer what broke. `testValidate()` does not.
- **Separate the phases**: Every test case has up to four phases — **Setup**, **Exercise**, **Verify**, **Teardown**. Label them. A reader should instantly see what scenario is being arranged, what action is being taken, and what outcome is expected.
- **Move noise below the test cases**: Helper methods, constants, and stub factories live beneath the test cases. The test body should read like a short story: given this scenario, when I do this, then I expect that.

## Isolation

- **One class/module under test per test file** — the System Under Test (SUT). Name the test after the *implementation*, not the interface (`PaymentServiceImplTest`, not `PaymentServiceTest`), so it's unambiguous what code is being exercised.
- **Use test doubles for behavioral collaborators**. The SUT's dependencies should be stubs or mocks, not real implementations. If a real dependency has a bug, only *its own* unit test should fail — no other tests should be affected. Think of test doubles like stunt doubles in movies: each one is tailored for a specific scene, playing a rehearsed part.
- **Don't mock data objects — mock behavioral collaborators, not data carriers**. A data object (entity, DTO, value object, record) carries state via getters/setters but has no business logic that could independently fail. Use real instances. This applies whether the data object is immutable (a value object, a record) or mutable (an entity with setters). Mocking a data object forces you to stub every property access (`when(order.getItems()).thenReturn(...)`) and makes state mutations invisible — `order.setStatus(CONFIRMED)` on a mock does nothing, so you're forced into `verify(order).setStatus(CONFIRMED)`, which is HOW-testing. With a real object, you simply assert `assertEquals(CONFIRMED, order.getStatus())` — pure WHAT-testing.
- **No temporal coupling**: Tests must not depend on wall-clock time, execution speed, or test ordering. If a function uses "now", make the clock injectable and stub it with a fixed value.

## Refactor-Friendliness

- **Specify only what's essential to each scenario**. If a test exercises expiry date calculation, it needs specific config values but doesn't need a specially tailored database mock — use a sensible default. Anything specified beyond what's necessary can break when unrelated code changes.
- **Absorb constructor changes into helper methods**. When a new dependency is added to the SUT, only the helper methods should change — not the individual test cases. This is like adding a new actor to a movie cast: you update the casting call, not every scene script where that actor doesn't appear. When the SUT gains a new dependency and existing tests don't exercise the new behavior, the new mock should work silently via its default stub behavior (returning null/false/0). Do not add stubs for a new mock into existing tests that have nothing to do with the new behavior — trust the defaults.
- **Test WHAT, not HOW**. This is the most important principle for refactor-friendliness. A test should verify the *outcome* (the WHAT) — the return value, the exception thrown, the state change — not *how* the SUT arrived at that outcome internally. Interaction verification (`verify()` calls) tests HOW by asserting which methods the SUT called, in what order, and how many times. This is over-specification: if you harmlessly reorder statements in the SUT, or add caching, or change which collaborator handles a subtask, tests that verify interactions will break even though the observable outcome hasn't changed.

  **Use `verify()` only for true fire-and-forget side effects** — analytics events, audit logs, outbound notifications — where there is literally no return value or state change to assert on. For everything else, assert on the outcome.

  **Common trap: `verify(mock, never()).method()`**. This looks like it's testing that something *didn't* happen, but it's actually testing an implementation detail. If a test for "out of stock" asserts `verify(repository, never()).save(any())`, it's saying "the SUT must not call save." But maybe a future refactor saves the order with a "rejected" status — the outcome (exception thrown, no fulfilled order) is the same, but the test breaks. Assert on the outcome (the exception, the error result), not on which internal methods were or weren't called.

- **Choose tools that preserve static binding**. Mocking techniques that use string-based method names break silently during IDE refactors. Prefer tools where renaming a method in the interface also updates the mock setup.

## Language-Specific Guidance

Read the appropriate reference file for tactical testing patterns:

| Language/Framework | Reference | Key Tools |
|---|---|---|
| React | `references/react.md` | React Testing Library, Jest/Vitest |
| TypeScript/Node | `references/typescript.md` | Jest/Vitest, constructor injection |
| Java | `references/java.md` | JUnit 5, Mockito, @InjectMocks |
| Kotlin | `references/kotlin.md` | JUnit 5, MockK |
| Python | `references/python.md` | pytest, unittest.mock, create_autospec |
| Ruby | `references/ruby.md` | RSpec, instance_double |
| Elixir | `references/elixir.md` | ExUnit, Mox |

Read ONLY the reference file matching the current language context.

> **Exemplar test file**: `src/features/ingest/__tests__/reconciliation.service.test.ts` in the trading-journal project demonstrates all TypeScript principles end-to-end.
