# Ruby Unit Testing

## Framework: RSpec + doubles

## Pattern

```ruby
RSpec.describe PaymentService do
  # Collaborators as verified doubles with sensible defaults
  let(:gateway) { instance_double(PaymentGateway) }
  let(:notifier) { instance_double(Notifier, notify: nil) }  # default: no-op

  subject(:sut) { described_class.new(gateway: gateway, notifier: notifier) }

  describe '#process_payment' do
    context 'when gateway approves' do
      before do
        # Setup — only essential collaborator
        allow(gateway).to receive(:charge).and_return(
          ChargeResult.new(transaction_id: 'tx-123', status: :approved)
        )
      end

      it 'returns a receipt with the transaction ID' do
        # Exercise
        receipt = sut.process_payment(amount: 100)

        # Verify — outcome
        expect(receipt.transaction_id).to eq('tx-123')
      end
    end

    context 'when gateway declines' do
      before do
        allow(gateway).to receive(:charge).and_return(
          ChargeResult.new(status: :declined, reason: 'insufficient funds')
        )
      end

      it 'raises PaymentDeclinedError' do
        expect { sut.process_payment(amount: 100) }
          .to raise_error(PaymentDeclinedError, /insufficient funds/)
      end
    end
  end
end
```

## `allow` vs `expect` to `receive` (WHAT vs HOW)

RSpec's DSL makes the WHAT-vs-HOW choice syntactically explicit — more so than any other framework:

1. **`allow(mock).to receive(:method).and_return(value)`**: Stubs behavior. The mock returns a canned answer so the SUT can proceed. Then you assert on the SUT's *outcome*. This tests WHAT happened.

2. **`expect(mock).to receive(:method)` / `have_received(:method)`**: Message expectations. RSpec asserts that the SUT called a specific method, optionally with specific arguments, a specific number of times, in a specific order. This tests HOW the SUT works internally.

**Use `allow` by default. Use `expect().to receive()` only for true fire-and-forget side effects** — analytics events, audit logs, outbound notifications — where there is no return value or state change to check.

```ruby
# BAD — message expectations on core flow
context 'when gateway declines' do
  before do
    allow(gateway).to receive(:charge).and_return(
      ChargeResult.new(status: :declined, reason: 'insufficient funds')
    )
  end

  it 'raises PaymentDeclinedError' do
    expect { sut.process_payment(amount: 100) }
      .to raise_error(PaymentDeclinedError, /insufficient funds/)

    expect(notifier).not_to have_received(:notify)        # over-specification!
    expect(gateway).to have_received(:charge).with(100)   # redundant!
  end
end

# GOOD — assert the outcome only
context 'when gateway declines' do
  before do
    allow(gateway).to receive(:charge).and_return(
      ChargeResult.new(status: :declined, reason: 'insufficient funds')
    )
  end

  it 'raises PaymentDeclinedError' do
    expect { sut.process_payment(amount: 100) }
      .to raise_error(PaymentDeclinedError, /insufficient funds/)
  end
end
```

The bad example says "the SUT must not call `notifier.notify`." But maybe a future refactor notifies on declined payments for fraud monitoring — the outcome (PaymentDeclinedError) is identical, but `not_to have_received` breaks. And `have_received(:charge).with(100)` adds nothing: if `charge` weren't called correctly, the SUT wouldn't have gotten the declined result to raise from.

```ruby
# BAD — chaining matchers amplifies over-specification
it 'processes the payment' do
  expect(gateway).to receive(:charge).with(100).exactly(:once).ordered
  expect(ledger).to receive(:record).with(hash_including(amount: 100)).ordered

  sut.process_payment(amount: 100)
end

# GOOD — stub and verify the outcome
it 'returns a receipt with the transaction ID' do
  allow(gateway).to receive(:charge).and_return(
    ChargeResult.new(transaction_id: 'tx-123', status: :approved)
  )

  receipt = sut.process_payment(amount: 100)

  expect(receipt.transaction_id).to eq('tx-123')
end
```

The bad example locks in call order, exact arguments, and call count for *two* collaborators. Reordering statements, adding caching, or changing how the ledger records data breaks the test — even if the outcome is identical. Note that `expect().to receive()` before the exercise also blurs the Setup/Exercise/Verify phases.

## Don't Mock Data Objects

Data objects (Structs, `Data.define` classes, plain Ruby objects with attributes) carry state — they don't have independent business logic that could fail. Mock *behavioral collaborators* (services, repositories, gateways), not *data carriers*.

Ruby makes test data trivially easy: `Struct.new(:items, :total)`, `Data.define(:items, :total)` (Ruby 3.2+), or plain classes with `attr_accessor`. There's no constructor ceremony to dodge.

The trap in Ruby is `double()` (unverified doubles). Like Python's `MagicMock`, an unverified `double` accepts any method call — if the SUT calls `order.cusomer_id` (typo), the double silently returns `nil` instead of raising `NoMethodError`. `instance_double` at least verifies the class has the methods you stub, but for data objects even that is over-engineering — just use the real thing.

```ruby
# BAD — unverified double for data: accepts anything silently
let(:order) { double('Order', items: [item], total: 99.0) }
let(:fraud_result) { double('FraudResult', flagged?: false) }

it 'processes the order' do
  allow(fraud_service).to receive(:check).and_return(fraud_result)
  allow(shipping_service).to receive(:create_label).and_return(
    double('ShippingLabel', tracking: 'TRACK-123')
  )

  sut.process(order)

  # order.status = :confirmed on a double does nothing — forced into HOW
  expect(order).to have_received(:status=).with(:confirmed)  # HOW-testing!
end

# GOOD — real data objects, assert on state
let(:order) { Order.new(items: [item], total: 99.0) }

it 'processes the order' do
  allow(fraud_service).to receive(:check).and_return(
    FraudResult.new(flagged: false)
  )
  allow(shipping_service).to receive(:create_label).and_return(
    ShippingLabel.new(tracking: 'TRACK-123')
  )

  result = sut.process(order)

  expect(result).to be_success
  expect(result.tracking).to eq('TRACK-123')
  expect(order.status).to eq(:confirmed)  # direct state check
end
```

Note: `instance_double(Order, items: [item])` is less dangerous than `double` because it verifies `Order` actually has an `items` method. But it's still unnecessary indirection — real `Order.new(items: [item])` is just as concise and gives you actual initialization logic, default values, and state you can assert on directly.

The rule of thumb: `Struct`, `Data.define`, `attr_accessor` class with no business logic? Use a real instance. Makes network calls or encapsulates complex behavior? Use `instance_double` with `allow` stubs.

## Guidelines

- **`instance_double` over `double`**: `instance_double` verifies the doubled class actually has the methods you stub — catches renames and API drift.
- **`let` blocks as sensible defaults**: Define collaborator doubles with default no-op behavior. Override in `before` blocks only for the specific scenario being tested.
- **`subject(:sut)`**: Names the SUT explicitly. `described_class.new` ties it to the class under test, so renaming the class auto-updates.
- **`allow` over `expect().to receive()` / `have_received`**: `allow` stubs behavior (WHAT); `expect` verifies interactions (HOW). Default to `allow` and assert on return values, exceptions, or state. Reserve message expectations for fire-and-forget side effects where no return value exists.
- **Avoid chaining verification matchers**: `.with(args).exactly(:once).ordered` on a message expectation locks in multiple implementation details at once. Each chained matcher is another way the test breaks during harmless refactoring.
- **Avoid `spy()` for core collaborators**: `spy()` creates a double that records all messages for later `have_received` assertions. This is explicitly opting into HOW-testing. Use `instance_double` with `allow` stubs instead.
- **Value objects as test data**: Ruby 3.2 `Data.define` creates immutable value objects. Use real instances in tests, not doubles. Structs and frozen objects also work.
- **`shared_context` for common setups**: Extract repeated setup into shared contexts, but keep them focused on one concern — they're the Ruby equivalent of helper methods in the test class.
