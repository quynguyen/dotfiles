# Kotlin Unit Testing

## Framework: JUnit 5 + MockK

## Pattern

```kotlin
class PaymentServiceTest {

    private val gateway: PaymentGateway = mockk()
    private val ledger: Ledger = mockk(relaxed = true)  // relaxed = sensible defaults
    private val sut = PaymentService(gateway, ledger)

    @Test
    fun `should return receipt when payment succeeds`() {
        // Setup — only essential collaborator behavior
        every { gateway.charge(any()) } returns ChargeResult.success(txId = "tx-123")

        // Exercise
        val receipt = sut.processPayment(Payment(amount = 100))

        // Verify — outcome, not interaction
        assertEquals("tx-123", receipt.transactionId)
    }

    @Test
    fun `should throw when gateway declines`() {
        // Setup
        every { gateway.charge(any()) } returns
            ChargeResult.declined("insufficient funds")

        // Exercise & Verify
        assertThrows<PaymentDeclinedException> {
            sut.processPayment(Payment(amount = 100))
        }
    }
}
```

## Coroutine Testing

```kotlin
@Test
fun `should propagate request context through coroutines`() = runTest {
    val ctx = RequestContext(userId = "user-1", traceId = "trace-1")

    withContext(ctx) {
        val result = sut.processOrder("order-123")
        assertEquals("order-123", result.orderId)
    }
}
```

## Stubs vs Verify Blocks (WHAT vs HOW)

MockK can serve two roles:

1. **Stubs** (`every { } returns`): Configure what a mock returns so the SUT can proceed. Then assert on the SUT's *outcome*. This tests WHAT happened.

2. **Verify blocks** (`verify { }`, `confirmVerified()`): Check which methods the SUT called on the mock, how many times, in what order. This tests HOW the SUT works internally.

**Stub by default. Verify only for true fire-and-forget side effects** — analytics, audit logs, outbound notifications — where there is no return value or state change to check.

MockK's concise lambda syntax makes `verify { }` feel lightweight and harmless, which makes it easy to add everywhere. Resist this — each verify block is a coupling point that breaks when implementation changes without affecting outcomes.

```kotlin
// BAD — tests HOW (internal interactions)
@Test
fun `should throw when gateway declines`() {
    every { gateway.charge(any()) } returns ChargeResult.declined("insufficient funds")

    assertThrows<PaymentDeclinedException> {
        sut.processPayment(Payment(amount = 100))
    }

    verify(exactly = 0) { ledger.record(any()) }    // over-specification!
    verify { gateway.charge(any()) }                  // redundant!
    confirmVerified(gateway, ledger)                   // over-specification!
}

// GOOD — tests WHAT (outcome only)
@Test
fun `should throw when gateway declines`() {
    every { gateway.charge(any()) } returns ChargeResult.declined("insufficient funds")

    assertThrows<PaymentDeclinedException> {
        sut.processPayment(Payment(amount = 100))
    }
}
```

The bad example says "the SUT must not call `ledger.record`." But maybe a future refactor records declined attempts for fraud analysis — the outcome (PaymentDeclinedException) is identical, but `verify(exactly = 0)` breaks. And `confirmVerified()` means *every* internal call must be accounted for — any refactoring that adds, removes, or reorders calls breaks the test.

```kotlin
// BAD — capturing arguments to verify internal wiring
@Test
fun `should return receipt when payment succeeds`() {
    val slot = slot<ChargeRequest>()
    every { gateway.charge(capture(slot)) } returns ChargeResult.success(txId = "tx-123")

    val receipt = sut.processPayment(Payment(amount = 100))

    assertEquals("tx-123", receipt.transactionId)
    assertEquals(100, slot.captured.amount)            // over-specification!
    verify(exactly = 1) { gateway.charge(any()) }      // redundant!
}

// GOOD — the return value IS the proof
@Test
fun `should return receipt when payment succeeds`() {
    every { gateway.charge(any()) } returns ChargeResult.success(txId = "tx-123")

    val receipt = sut.processPayment(Payment(amount = 100))

    assertEquals("tx-123", receipt.transactionId)
}
```

If `receipt.transactionId` is "tx-123", the SUT *must* have called the gateway correctly — the return value proves it. The `slot` capture and `verify` just make the test break when you refactor how charges are constructed internally.

## Don't Mock Data Objects

Data objects (`data class`, enum entries, value classes) carry state — they don't have independent business logic that could fail. Mock *behavioral collaborators* (services, repositories, gateways), not *data carriers*.

Kotlin makes this especially easy: `data class` gives you a constructor with named parameters, `copy()` for variations, and destructuring — all for free. There's no excuse to reach for `mockk()` on something that's trivially constructable.

Mocking a data class with `mockk()` creates two problems specific to Kotlin:

1. **Null safety bypass.** `mockk<Order>()` returns `null` for non-nullable properties unless you configure `every { }` for each one. Your test compiles, but the SUT crashes at runtime with a `NullPointerException` on what Kotlin guarantees can't be null — the type system is lying to you.

2. **The same cascade as Java.** Every property needs `every { } returns`, mutations need `every { order.status = any() } just Runs`, and you're forced into `verify { }` to check what should be a direct property assertion.

```kotlin
// BAD — mocks data objects, cascading into HOW-testing
@Test
fun `should process order`() {
    val order: Order = mockk()  // mocking a data carrier
    every { order.items } returns listOf(item)
    every { order.paymentMethod } returns "VISA"
    every { order.total } returns BigDecimal("99.00")
    every { order.status = any() } just Runs
    // order.customerId is non-nullable String — but mockk returns null!

    val fraudResult: FraudResult = mockk()
    every { fraudResult.isFlagged } returns false

    every { fraudService.check(order) } returns fraudResult

    sut.processOrder(order)

    // order.status = CONFIRMED on a mockk is invisible — forced into verify
    verify { order.status = OrderStatus.CONFIRMED }  // HOW-testing!
}

// GOOD — real data objects, assert on state
@Test
fun `should process order`() {
    val order = Order("ord-1", "cust-1", listOf(item), "VISA", BigDecimal("99.00"))
    every { fraudService.check(order) } returns FraudResult(isFlagged = false)
    every { shippingService.createLabel(any(), any()) } returns
        ShippingLabel("TRACK-123", "123 Main St")

    val result = sut.processOrder(order)

    assertTrue(result.isSuccess)
    assertEquals("TRACK-123", result.trackingNumber)
    assertEquals(OrderStatus.CONFIRMED, order.status)  // direct state check
}
```

Use `copy()` to create test data variations without repeating the full constructor:

```kotlin
val baseOrder = Order("ord-1", "cust-1", listOf(item), "VISA", BigDecimal("99.00"))

// Each test varies only what matters
val largeOrder = baseOrder.copy(total = BigDecimal("10000.00"))
val emptyOrder = baseOrder.copy(items = emptyList())
```

The rule of thumb: if a class is a `data class` or primarily properties/constructors, use a real instance — named parameters make even large constructors readable. If it makes network calls or encapsulates complex behavior, mock it.

## Guidelines

- **`relaxed = true` for non-essential collaborators**: Non-relaxed mocks throw on unconfigured calls, which pressures you to stub every call path. Use `relaxed = true` for collaborators that aren't essential to the scenario — it returns sensible defaults (0, false, empty strings, empty lists) without requiring explicit stubs.
- **`every { } returns`** preserves static binding. IDE renames propagate to mock setup.
- **Backtick test names**: Kotlin allows spaces in function names with backticks, making test names readable sentences.
- **`runTest`** from `kotlinx-coroutines-test` for testing suspend functions. It controls virtual time, eliminating temporal coupling.
- **Data classes as test data**: Kotlin data classes are immutable facts — use real instances, never mocks.
- **Stub, don't verify**: Use `every { } returns` to set up scenarios, then assert on the SUT's output. Avoid `verify { }`, `verify(exactly = 0) { }`, and `confirmVerified()` for core flow. Reserve verification for fire-and-forget side effects where no return value exists.
- **Avoid `confirmVerified()`**: It requires every mock interaction to be explicitly verified — the ultimate over-specification. Any refactoring that changes internal call patterns breaks every test.
- **Avoid `slot()` / `capture()` for core flow**: Argument capture tests what was passed to a collaborator (HOW), not what the SUT produced (WHAT). If the SUT's return value is correct, the right data must have flowed through.
- **`coEvery` / `coVerify`** for suspend functions. The same WHAT-vs-HOW principle applies — prefer `coEvery` stubs with outcome assertions over `coVerify` blocks.
