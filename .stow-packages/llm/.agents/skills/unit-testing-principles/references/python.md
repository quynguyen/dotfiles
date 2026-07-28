# Python Unit Testing

## Framework: pytest + unittest.mock

## Anti-Pattern: Monkeypatching Internals

```python
# BAD: Patching private implementation details
def test_process_order(monkeypatch):
    monkeypatch.setattr('myapp.services.order._validate_inventory', lambda x: True)
    monkeypatch.setattr('myapp.services.order._calculate_tax', lambda x: 10.0)
    result = process_order(order)
    assert result.total == 110.0
```

This test breaks when internal functions are renamed or moved — a refactor that doesn't change behavior.

## Pattern: Dependency Injection + Fixtures

```python
from unittest.mock import create_autospec

class OrderService:
    def __init__(self, inventory: InventoryStore, tax: TaxCalculator):
        self.inventory = inventory
        self.tax = tax

class TestOrderService:

    @pytest.fixture
    def inventory(self):
        return create_autospec(InventoryStore)

    @pytest.fixture
    def tax(self):
        return create_autospec(TaxCalculator)

    @pytest.fixture
    def sut(self, inventory, tax):
        return OrderService(inventory=inventory, tax=tax)

    def test_should_calculate_total_with_tax(self, sut, inventory, tax):
        # Setup — only essential behavior
        inventory.check.return_value = True
        tax.calculate.return_value = Decimal("10.00")

        # Exercise
        result = sut.process(Order(subtotal=Decimal("100.00")))

        # Verify — outcome
        assert result.total == Decimal("110.00")

    def test_should_fail_when_out_of_stock(self, sut, inventory):
        # Setup — only inventory matters; tax not configured (default)
        inventory.check.return_value = False

        # Exercise & Verify
        with pytest.raises(OutOfStockError):
            sut.process(Order(subtotal=Decimal("100.00")))
```

## Configuring Behavior vs Asserting Calls (WHAT vs HOW)

`unittest.mock` objects serve two purposes on the same object:

1. **Configuring behavior** (`.return_value`, `.side_effect`): Set up what the mock returns so the SUT can proceed. Then assert on the SUT's *outcome*. This tests WHAT happened.

2. **Asserting calls** (`.assert_called_with()`, `.assert_not_called()`, `.call_args_list`): Check which methods the SUT called on the mock. This tests HOW the SUT works internally.

**Configure behavior by default. Assert calls only for true fire-and-forget side effects** — analytics, audit logs, outbound notifications — where there is no return value or state change to check.

Because both capabilities live on the same object, it's tempting to always add call assertions alongside return-value setup. Resist this — it over-specifies, and the tests break when implementation changes without affecting outcomes.

**`assert_not_called()` is almost never appropriate** — even for fire-and-forget collaborators. Test fire-and-forget positively: "notification was sent on success" (one test with `assert_called_once_with`). Don't test negatively: "notification was not sent on failure" — the failure path's outcome (e.g., `result.rejection_reason`) is the assertion. If the code later starts sending notifications on failure too, that's a new behavior that deserves a new positive test, not a broken negative one.

```python
# BAD — tests HOW (what was called internally)
def test_should_fail_when_out_of_stock(self, sut, inventory, payment):
    inventory.check.return_value = False

    with pytest.raises(OutOfStockError):
        sut.process(order)

    payment.charge.assert_not_called()      # over-specification!
    inventory.check.assert_called_once()    # over-specification!

# GOOD — tests WHAT (outcome only)
def test_should_fail_when_out_of_stock(self, sut, inventory):
    inventory.check.return_value = False

    with pytest.raises(OutOfStockError):
        sut.process(order)
```

The bad example says "the SUT must not call `payment.charge`." But maybe a future refactor pre-authorizes charges and reverses them on failure — the outcome (OutOfStockError) is identical, but `assert_not_called()` breaks. And `assert_called_once()` on inventory adds nothing: if `check` weren't called, the test would already fail because the SUT wouldn't know the item is out of stock.

```python
# BAD — verifying the happy path's internal interactions
def test_should_calculate_total_with_tax(self, sut, inventory, tax):
    inventory.check.return_value = True
    tax.calculate.return_value = Decimal("10.00")

    result = sut.process(order)

    assert result.total == Decimal("110.00")
    inventory.check.assert_called_once_with(order.item_id)  # redundant!
    tax.calculate.assert_called_once_with(order.subtotal)    # redundant!

# GOOD — the return value IS the proof
def test_should_calculate_total_with_tax(self, sut, inventory, tax):
    inventory.check.return_value = True
    tax.calculate.return_value = Decimal("10.00")

    result = sut.process(order)

    assert result.total == Decimal("110.00")
```

If `result.total` is correct, then the SUT *must* have called the right collaborators with the right inputs — the return value proves it. Adding `assert_called_once_with` just makes the test break when you refactor how the SUT gets inventory or tax data.

## Don't Mock Data Objects

Data objects (`@dataclass`, Pydantic models, `NamedTuple`, `attrs` classes, plain classes with attributes) carry state — they don't do anything that could fail in a test. Use real instances, not mocks.

The problem in Python is specific: **`MagicMock` is a universal acceptor.** It says yes to everything — any attribute access returns another MagicMock, any method call succeeds, any comparison is truthy. When you use it for data, your test passes not because the logic is correct, but because MagicMock absorbs every operation without complaint.

```python
# BAD — MagicMock as data: silent fabrication and type evasion
def test_should_process_order(self, sut, fraud_service):
    order = MagicMock()
    order.items = [item]
    order.total = Decimal("99.00")

    fraud_service.check.return_value = MagicMock(flagged=False)

    result = sut.process(order)

    assert result.success
```

Three problems hiding here:

1. **Silent attribute fabrication.** If the SUT accesses `order.cusomer_id` (typo), MagicMock silently returns a MagicMock — no `AttributeError`. A real `@dataclass` would catch this immediately. The test "passes" with nonsense data flowing through the system.

2. **Type evasion.** `order.total` is a real `Decimal` because we set it, but if the SUT accesses any attribute we *didn't* set, it gets a MagicMock, not the expected type. `order.subtotal * tax_rate` returns a MagicMock, not a number. Arithmetic "works" because MagicMock implements `__mul__`, but the result is meaningless.

3. **Validation bypass.** If `Order` is a Pydantic model, construction validates field types, required fields, and custom validators. `MagicMock()` bypasses all of it — your test accepts data shapes that could never exist in production.

```python
# GOOD — real data objects
def test_should_process_order(self, sut, fraud_service):
    order = Order(items=[item], total=Decimal("99.00"), customer_id="cust-1")
    fraud_service.check.return_value = FraudResult(flagged=False)

    result = sut.process(order)

    assert result.success
    assert result.tracking == "TRACK-123"
    assert order.status == "confirmed"  # direct state check
```

Real objects give you type safety, validation, and `AttributeError` on typos — for free. Even `create_autospec(Order)` is worse than a real `Order`: it validates method signatures but still returns MagicMocks for attribute access, and it bypasses `__init__` validation.

The rule of thumb: `@dataclass`, Pydantic model, `NamedTuple`, `attrs` class, plain class with attributes? Use a real instance. Makes network calls, queries a database, calls external services? Mock it.

## Guidelines

- **`create_autospec()` over `MagicMock()`**: Autospec validates that stubbed methods actually exist on the interface, catching renames at test time. This preserves refactor-safety.
- **pytest fixtures as the `createSUT()` equivalent**: The `sut` fixture assembles the SUT with default mocked collaborators. Override individual fixtures per test class or function for specific scenarios.
- **`@dataclass(frozen=True)` for test data**: Immutable data objects are facts — use real instances, not mocks.
- **Avoid `monkeypatch` for internal functions**: Inject dependencies explicitly instead. `monkeypatch` couples tests to import paths and internal structure, not to contracts.
- **`contextvars` in tests**: Set the context var in the test's setup; it will be visible to the SUT during the exercise phase.
- **Configure behavior, don't assert calls**: Use `.return_value` and `.side_effect` to set up scenarios, then assert on the SUT's output. Avoid `.assert_called_with()`, `.assert_called_once()`, and `.call_args_list` for core flow. Reserve call assertions for fire-and-forget side effects where no return value exists — and only as *positive* tests ("was called on success"). Never use `.assert_not_called()` on failure paths; the outcome (exception, rejection reason) is the assertion.
