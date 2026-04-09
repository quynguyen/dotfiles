# Elixir Unit Testing

## Framework: ExUnit + Mox

Mox implements José Valim's "mocks and explicit contracts" pattern: mock only behaviours (interfaces), never concrete modules.

## Pattern

```elixir
# 1. Define a behaviour (the interface/contract)
defmodule MyApp.PaymentGateway do
  @callback charge(amount :: integer()) :: {:ok, String.t()} | {:error, String.t()}
end

# 2. Define the mock in test_helper.exs
Mox.defmock(MyApp.MockPaymentGateway, for: MyApp.PaymentGateway)

# 3. Test with Mox
defmodule MyApp.PaymentServiceTest do
  use ExUnit.Case, async: true
  import Mox

  setup :verify_on_exit!

  describe "process_payment/1" do
    test "returns receipt when charge succeeds" do
      # Setup — only essential collaborator behavior
      stub(MyApp.MockPaymentGateway, :charge, fn 100 ->
        {:ok, "tx-123"}
      end)

      # Exercise
      result = PaymentService.process_payment(100,
        gateway: MyApp.MockPaymentGateway
      )

      # Verify — outcome
      assert {:ok, %Receipt{transaction_id: "tx-123"}} = result
    end

    test "returns error when charge fails" do
      stub(MyApp.MockPaymentGateway, :charge, fn _amount ->
        {:error, "declined"}
      end)

      result = PaymentService.process_payment(100,
        gateway: MyApp.MockPaymentGateway
      )

      assert {:error, "declined"} = result
    end
  end
end
```

## `stub` vs `expect` (WHAT vs HOW)

Mox's `expect/3` bundles two operations that other frameworks keep separate:

1. **Configuring behavior**: When the function is called, run this anonymous function and return its result.
2. **Enforcing call count**: Assert the function is called exactly N times (default 1). `verify_on_exit!` checks this after the test.

This fusion is Mox's defining design choice. But it means every `expect` call silently adds a call-count assertion — a form of HOW-testing. Mox's `stub/3` provides the same behavior configuration *without* enforcing call count.

**Use `stub` for core collaborators whose return values flow into the outcome. Use `expect` for fire-and-forget side effects** — analytics, audit logs, outbound notifications — where verifying the call happened *is* the test.

```elixir
# OVER-SPECIFIED — expect enforces call count on core flow
test "returns receipt when charge succeeds" do
  expect(MyApp.MockPaymentGateway, :charge, fn 100 ->
    {:ok, "tx-123"}
  end)

  result = PaymentService.process_payment(100,
    gateway: MyApp.MockPaymentGateway
  )

  assert {:ok, %Receipt{transaction_id: "tx-123"}} = result
end

# BETTER — stub for core collaborator, let the outcome speak
test "returns receipt when charge succeeds" do
  stub(MyApp.MockPaymentGateway, :charge, fn 100 ->
    {:ok, "tx-123"}
  end)

  result = PaymentService.process_payment(100,
    gateway: MyApp.MockPaymentGateway
  )

  assert {:ok, %Receipt{transaction_id: "tx-123"}} = result
end
```

Both tests verify the outcome via pattern matching. The difference: if a future refactor calls `:charge` twice (e.g., retry on timeout), the `expect` version fails because the call count changed from 1 to 2. The `stub` version passes because the outcome is still correct.

```elixir
# GOOD — expect is right for fire-and-forget side effects
test "sends notification after successful payment" do
  stub(MyApp.MockPaymentGateway, :charge, fn _amount ->
    {:ok, "tx-123"}
  end)

  # This IS the test — verify the notification was sent
  expect(MyApp.MockNotifier, :notify, fn :payment_received, %{tx_id: "tx-123"} ->
    :ok
  end)

  PaymentService.process_payment(100,
    gateway: MyApp.MockPaymentGateway,
    notifier: MyApp.MockNotifier
  )
end
```

Here `expect` is justified: there's no return value that proves the notification was sent. The call *is* the outcome being tested.

## Don't Mock Data Objects

Elixir's design largely prevents this problem. Structs are immutable data — not modules with callbacks — so Mox can't mock them. You create test data by constructing structs directly: `%Order{items: [item], total: Decimal.new("99.00")}`. There's no mechanism to accidentally mock data the way there is in object-oriented languages.

The rare anti-pattern is wrapping data access behind unnecessary behaviours just to use Mox:

```elixir
# BAD — unnecessary behaviour wrapping data access
defmodule MyApp.OrderData do
  @callback get_items(map()) :: list()
  @callback get_total(map()) :: Decimal.t()
end

# Now you're mocking data access instead of using the struct directly
test "processes the order" do
  expect(MyApp.MockOrderData, :get_items, fn _order -> [item] end)
  expect(MyApp.MockOrderData, :get_total, fn _order -> Decimal.new("99.00") end)
  # ...
end

# GOOD — use the struct directly
test "processes the order" do
  order = %Order{items: [item], total: Decimal.new("99.00"), status: :pending}

  stub(MyApp.MockFraudService, :check, fn _order ->
    %FraudResult{flagged: false}
  end)

  result = PaymentService.process(order,
    fraud_service: MyApp.MockFraudService
  )

  assert result.success
  assert result.order.status == :confirmed
end
```

If you find yourself defining a behaviour just to get data into a test, you're fighting the language. Structs, maps, and tuples are data — use them directly. Reserve Mox for modules with side effects (network calls, database queries, external services).

## Guidelines

- **Mox enforces behaviours**: You can only mock modules that define `@callback` specs. This ensures mocks stay in sync with the real contract — Elixir's equivalent of interface-based mocking.
- **Dependency injection via options or config**: Pass mock modules as keyword options (`gateway: MockGateway`) or configure via `Application.get_env`. This is Elixir's idiomatic equivalent of constructor injection.
- **`async: true` for isolation**: Each test runs in its own process. Mox expectations are process-scoped, preventing cross-test interference.
- **Structs as test data**: Elixir structs are immutable by default — use real instances, never mocks. They're facts.
- **`setup` blocks** for common configuration shared across tests in a describe block. Test-specific stubs and expectations belong in the test body.
- **`stub` for core collaborators, `expect` for side effects**: `stub/3` configures behavior without enforcing call count — the return value proves the collaborator was called correctly. `expect/3` adds call-count verification, which is only needed for fire-and-forget side effects where the call itself is the outcome. Don't use `expect` as a stricter `stub`.
- **`verify_on_exit!` amplifies `expect`'s HOW-ness**: Every `expect` becomes a call-count assertion checked after the test. The more `expect` calls you use, the more implementation details `verify_on_exit!` enforces.
- **Pattern matching in assertions**: `assert {:ok, %Receipt{transaction_id: "tx-123"}} = result` is both the verify step and a documentation of the expected output shape.
