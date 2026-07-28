---
name: api-design-principles
description: |
  Enforce separation of essential and incidental data in API signatures. Use this skill whenever writing or reviewing function signatures, method parameters, component props, or interface contracts. Triggers on: designing APIs, reviewing parameter lists, handling cross-cutting concerns (logging, auth, tracing, analytics), encountering prop drilling, passing context (requestId, userId, traceId) through service layers, deciding between explicit parameters vs ambient context (ThreadLocal, React Context, AsyncLocalStorage, contextvars), or refactoring bloated interfaces. Also triggers when discussing coupling between modules or data that passes through intermediate layers without being used.
---

# API Design Principles: Essential vs Incidental Data

## Core Principle

Parameters are a *data-passing mechanism* — one of many. Every parameter creates a coupling between caller, callee, and the type of the data being passed. This coupling is the **cost** of using parameters.

That cost is justified when the data is **essential** — data without which the function cannot fulfill its core purpose. It is unjustified when the data is **incidental** — data needed only for secondary concerns like logging, security, analytics, or tracing.

**An API should change only when what is essential to it changes.**

## The Three Questions

Before adding a parameter, ask:

1. **Why** are we passing this data?
2. **What concern** does it serve?
3. **Is that concern essential or incidental** to this function's core purpose?

If you removed the parameter and the function could still fulfill its primary responsibility (just without logging, tracing, auth context, etc.), the data is incidental and should not be a parameter.

## Anti-Pattern: Parameter Pollution

When incidental data is passed as parameters, every intermediate layer between the data's origin and its destination becomes coupled to it. Adding a new incidental concern (say, analytics) forces signature changes through every function in the call chain — even those that merely relay the data without using it.

This destroys reusability and modularity. A function designed for one concern becomes welded to an application's specific cross-cutting needs.

**Example 1 — Before (polluted):**
```
getAccounts(bankId, accountId, userId, sessionId, ipAddress)
```
The last three parameters are incidental — needed for logging, not for fetching accounts. Every caller must provide them; the function can't be reused in a context without user sessions.

**Example 2 — After (clean):**
```
getAccounts(bankId, accountId)
```
Only essential data. Incidental data (user, session) flows through ambient context, set once at the request boundary.

## Pattern: Ambient Context for Incidental Data

Route incidental data through contextual mechanisms that don't pollute function signatures:

- **Write once, read anywhere**: Capture incidental data (user ID, request ID, trace context) at the system boundary. Make it available to any code that needs it without explicit parameter passing.
- **Encapsulate the mechanism**: Consuming code depends on a reader interface, not the storage mechanism. This preserves testability and allows swapping implementations.
- **Immutability**: Contextual data, once written, should be immutable to consumers. Readers get a snapshot they cannot modify.
- **Separate events from concerns**: After cleaning the method signature, a natural next step is to inject `AuditLogger` into the implementation class and call it directly — **this is still wrong**. The implementation class now depends on an incidental concern it doesn't own; adding analytics requires changing it. Instead: define an `EventHandler` interface (nested in the implementation class) with methods named after domain facts (`accountsFetched`, `accountsFetchFailed`). The implementation fires these events; a separate handler class reads ambient context and logs. The essential code announces *what happened*; a separate handler decides *what to do about it*. The implementation class has zero knowledge of logging, audit, or tracing.

## Language-Specific Guidance

Read the appropriate reference file based on the language/framework in use:

| Language/Framework | Reference | Ambient Mechanism |
|---|---|---|
| React | `references/react.md` | Context API / Providers |
| TypeScript/Node | `references/typescript.md` | AsyncLocalStorage |
| Java | `references/java.md` | ThreadLocal + Reader/Writer interfaces |
| Kotlin | `references/kotlin.md` | Coroutine Context |
| Python | `references/python.md` | contextvars |
| Ruby | `references/ruby.md` | RequestStore / CurrentAttributes |
| Elixir | `references/elixir.md` | Process dictionary / Logger.metadata |

Read ONLY the reference file matching the current language context.

## Connection to Testing

When APIs contain only essential parameters, unit testing becomes natural: test doubles only need to provide essential data. Incidental data flows through ambient context, which tests can configure independently. This is the foundation of the companion skill `unit-testing-principles`.
