# Kotlin: Essential vs Incidental Data

## Ambient Mechanism: Coroutine Context

Kotlin coroutines carry a `CoroutineContext` that flows automatically through `suspend` functions and child coroutines, making it ideal for incidental data.

## Anti-Pattern

```kotlin
// Request context leaks through every layer
suspend fun processPayment(
    paymentId: String,
    userId: String,       // incidental
    traceId: String,      // incidental
    logger: Logger        // incidental
): PaymentResult {
    logger.info("Processing $paymentId for $userId [$traceId]")
    return executePayment(paymentId, userId, traceId, logger)
}
```

## Pattern: CoroutineContext for Incidental Data

```kotlin
// Define a context element for request-scoped data
data class RequestContext(
    val userId: String,
    val traceId: String
) : AbstractCoroutineContextElement(Key) {
    companion object Key : CoroutineContext.Key<RequestContext>
}

// Read from coroutine context anywhere
suspend fun currentRequestContext(): RequestContext =
    coroutineContext[RequestContext]
        ?: error("No RequestContext in coroutine scope")

// Set at the request boundary
suspend fun handleRequest(req: Request, block: suspend () -> Response): Response =
    withContext(RequestContext(userId = req.userId, traceId = req.traceId)) {
        block()
    }

// Clean function — only essential data
suspend fun processPayment(paymentId: String): PaymentResult {
    val ctx = currentRequestContext() // incidental, from ambient context
    logger.info("Processing $paymentId for ${ctx.userId} [${ctx.traceId}]")
    return executePayment(paymentId)
}
```

## Guidelines

- **CoroutineContext flows automatically** through `suspend` calls and child coroutines — no manual propagation needed.
- **Use `AbstractCoroutineContextElement`** for custom context data. Each element has a unique `Key`.
- **Immutability**: Context elements should be `data class` (immutable by convention).
- **Ktor**: Use custom CoroutineContext elements in route handlers, or `call.attributes` for request-scoped data.
- **Spring + Kotlin**: For coroutine-based Spring, use CoroutineContext directly. For reactive Spring, use `ReactorContext` bridge.
- **ThreadLocal bridge**: When calling blocking Java code from coroutines, use `ThreadLocal.asContextElement()` to bridge the two worlds.
