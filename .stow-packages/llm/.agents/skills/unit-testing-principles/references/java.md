# Java Unit Testing

## Framework: JUnit 5 + Mockito

## Structure with @InjectMocks

Mockito's `@InjectMocks` creates the SUT with `@Mock` dependencies auto-injected — eliminating manual `createSUT()` boilerplate. Fresh mocks are created before each test, providing natural isolation.

```java
@ExtendWith(MockitoExtension.class)
class SchedulePanChangeServiceImplTest {

    @Mock private Config config;
    @Mock private MemberDAO memberDAO;
    @Mock private PanMigrationDAO panMigrationDAO;
    @InjectMocks private SchedulePanChangeServiceImpl sut;

    @Test
    void shouldConstruct() {
        // Verify
        assertNotNull(sut);
    }

    @Test
    void shouldReturnResultWithCorrectExpiryDate() {
        // Setup — specify only what's essential to this scenario
        expectMemberExists(OLD_PAN);
        expectConfig(NOW, DAYS_TO_EXPIRE);

        // Exercise
        PanChangeResult result = sut.validateAndSchedulePanChange(PAN_CHANGE);

        // Verify — assert on the outcome, not on internal calls
        long actual = TimeUnit.DAYS.convert(
            result.getExpiryDate().getTime() - NOW, TimeUnit.MILLISECONDS);
        assertEquals(DAYS_TO_EXPIRE, actual);
    }

    @Test
    void shouldFailWhenNoMemberWithOldPanExists() {
        // No setup needed — mocks return null/false by default
        // Exercise & Verify
        assertThrows(MemberNotFoundException.class,
            () -> sut.validateAndSchedulePanChange(PAN_CHANGE));
    }

    // *** Helper Methods — named for intent, not mechanics ***

    private void expectMemberExists(String pan) {
        when(memberDAO.doesMemberExistByPan(BIN, pan)).thenReturn(true);
    }

    private void expectConfig(long now, int daysToExpire) {
        when(config.now()).thenReturn(now);
        when(config.getNumDaysBeforeExpiry()).thenReturn(daysToExpire);
    }

    private static final long NOW = System.currentTimeMillis();
    private static final int DAYS_TO_EXPIRE = 18;
    // ... constants and test data
}
```

## Stubs vs Expectation Verification (WHAT vs HOW)

Mockito mocks can serve two roles:

1. **Stubs** (`when().thenReturn()`): Provide canned answers so the SUT can proceed. The test then asserts on the SUT's *outcome* — the return value, exception, or state change. This tests WHAT happened.

2. **Expectation Verification** (`verify()`): Records which methods the SUT called on the mock. The test asserts on internal *interactions* — which methods were called, how many times, in what order. This tests HOW the outcome was achieved.

**Use stubs (WHAT) by default. Use verification (HOW) only for true fire-and-forget side effects** where there is literally no return value or state change to check — analytics events, audit logs, outbound notifications.

The reason: if you test HOW, you're testing implementation details. Suppose you add caching, reorder statements, or change which collaborator handles a subtask. The observable outcome stays the same, but `verify()` tests break because the internal call sequence changed. That's a test working against changeability.

```java
// BAD — tests HOW (implementation detail)
@Test
void shouldFailWhenItemOutOfStock() {
    expectItemOutOfStock(ITEM_ID);
    assertThrows(OutOfStockException.class, () -> sut.fulfillOrder(order));
    verify(repository, never()).save(any());   // over-specification!
    verify(shippingCalc, never()).calculate(any()); // over-specification!
}

// GOOD — tests WHAT (outcome only)
@Test
void shouldFailWhenItemOutOfStock() {
    // Setup — only what's essential to this scenario
    expectItemOutOfStock(ITEM_ID);
    // Exercise & Verify — assert the outcome
    assertThrows(OutOfStockException.class, () -> sut.fulfillOrder(order));
}
```

The `verify(never())` calls in the bad example say "the SUT must not call save or calculate." But why does the test care? Maybe a future refactor saves rejected orders for reporting, or pre-calculates shipping for UX purposes. The *outcome* (OutOfStockException) is what matters, not which internal methods were or weren't invoked.

## Don't Mock Data Objects

Data objects (entities, DTOs, value objects, records) carry state — they don't have independent business logic that could fail. Mock *behavioral collaborators* (services, repositories, gateways), not *data carriers*.

Mocking a data object creates a cascade of problems: every getter needs stubbing, state mutations become invisible, and you're forced into `verify()` to check what should be a simple state assertion.

```java
// BAD — mocks data objects, cascading into HOW-testing
@Mock Order order;
@Mock FraudResult fraudResult;
@Mock ShippingLabel shippingLabel;

@Test
void shouldProcessOrder() {
    // Must stub every property access on the mock
    when(order.getItems()).thenReturn(List.of(item));
    when(order.getPaymentMethod()).thenReturn("VISA");
    when(order.getTotal()).thenReturn(new BigDecimal("99.00"));
    when(fraudResult.isFlagged()).thenReturn(false);
    when(shippingLabel.getTrackingNumber()).thenReturn("TRACK-123");
    when(fraudService.check(order)).thenReturn(fraudResult);
    when(shippingService.createLabel(any(), any())).thenReturn(shippingLabel);

    sut.processOrder(order);

    // order.setStatus(CONFIRMED) on a mock does nothing — forced into verify
    verify(order).setStatus(OrderStatus.CONFIRMED);  // HOW-testing!
}

// GOOD — real data objects, assert on state
@Test
void shouldProcessOrder() {
    // Setup — real objects, no stubbing needed for properties
    Order order = new Order("ord-1", "cust-1", List.of(item), "VISA", new BigDecimal("99.00"));
    when(fraudService.check(order)).thenReturn(new FraudResult(false));
    when(shippingService.createLabel(any(), any()))
        .thenReturn(new ShippingLabel("TRACK-123", "123 Main St"));

    // Exercise
    OrderResult result = sut.processOrder(order);

    // Verify — assert on outcome (WHAT), not internal calls (HOW)
    assertTrue(result.isSuccess());
    assertEquals("TRACK-123", result.getTrackingNumber());
    assertEquals(OrderStatus.CONFIRMED, order.getStatus());  // direct state check
}
```

The rule of thumb: if a class is primarily getters/setters/constructors with no business logic, use a real instance. If it makes network calls, queries a database, or encapsulates complex behavior, mock it.

## Guidelines

- **Mockito stubs are lenient by default**: Un-stubbed methods return null/0/false. Tests that don't care about a collaborator's behavior don't need to configure it — this is the natural "sensible default." When a new `@Mock` field is added for a new dependency, existing tests should not stub it — trust the defaults.
- **Stubs over verify()**: Use `when().thenReturn()` to set up scenarios, then assert on the SUT's output. Reserve `verify()` exclusively for fire-and-forget side effects (analytics, audit logs, outbound notifications) where no return value exists to assert on.
- **Never use `verify(mock, never())` for core flow**: `verify(repo, never()).save(any())` is testing an implementation detail, not an outcome. Assert on the outcome instead (exception thrown, error result returned, unchanged state).
- **Name test methods as behavior descriptions**: `shouldFailWhenDuplicatePanChangeAlreadyScheduled()` tells a developer exactly what scenario broke.
- **Mockito preserves static binding**: Renaming a method via IDE refactor also renames it in `when()` and `verify()` calls. This is why Mockito is preferred over string-based mocking frameworks (e.g., JMockit's MockUp).
- **Helper methods named for intent**: `expectMemberExists(pan)` reads as a precondition, not as implementation wiring. Helpers live below the test cases where they don't distract the reader.
- **Adding a new collaborator**: When a new dependency is added to the SUT's constructor, add a `@Mock` field. No test case code changes — `@InjectMocks` handles the wiring automatically, and Mockito's defaults mean the new mock is silently present without needing explicit stubs in existing tests.
