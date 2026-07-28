# TypeScript/Node Unit Testing

## Framework: Jest or Vitest

## Anti-Pattern: Real Dependencies in Tests

```typescript
// BAD: Using real database connection — fails if DB is down or has different data
it('should return user by ID', async () => {
  const service = new UserService(realDatabase);
  const user = await service.getUser('123');
  expect(user.name).toBe('Alice');
});
```

## Pattern: Constructor Injection + Stub Helpers

```typescript
// Interface for the dependency
interface UserStore {
  findById(id: string): Promise<User | null>;
}

// SUT depends on interface, not implementation
class UserService {
  constructor(private readonly store: UserStore) {}

  async getUser(id: string): Promise<User> {
    const user = await this.store.findById(id);
    if (!user) throw new UserNotFoundError(id);
    return user;
  }
}

// Test
describe('UserService', () => {
  // createSUT with sensible defaults — override only what matters
  function createSUT(overrides: Partial<{ store: UserStore }> = {}) {
    const store = overrides.store ?? { findById: async () => null };
    return new UserService(store);
  }

  it('should throw when user not found', async () => {
    // Setup — default store returns null, which is what we want
    const sut = createSUT();

    // Exercise & Verify
    await expect(sut.getUser('missing')).rejects.toThrow(UserNotFoundError);
  });

  it('should return user when found', async () => {
    // Setup — tailor only the store behavior
    const sut = createSUT({
      store: { findById: async () => ({ id: '1', name: 'Alice' }) },
    });

    // Exercise
    const user = await sut.getUser('1');

    // Verify
    expect(user.name).toBe('Alice');
  });
});
```

## Plain Stubs vs jest.fn() Spying (WHAT vs HOW)

TypeScript's structural typing gives you a natural advantage: you can stub dependencies with plain objects and functions, no mocking library needed. This is inherently WHAT-testing — there's nothing to verify because there's no call tracking.

The HOW-testing trap starts when you reach for `jest.fn()` or `vi.fn()`:

1. **Plain function stubs** (`{ method: async () => value }`): Provide canned answers so the SUT can proceed. Assert on the SUT's *outcome*. Tests WHAT happened. No call tracking.

2. **Spy functions** (`jest.fn()`, `vi.fn()`, `jest.spyOn()`): Track every call — arguments, count, order. Enable `.toHaveBeenCalledWith()`, `.not.toHaveBeenCalled()`, `.toHaveBeenCalledTimes()`. Tests HOW the SUT works internally.

**Use plain stubs by default. Use `jest.fn()` only for true fire-and-forget side effects** — analytics callbacks, event emitters, outbound notifications — where there is no return value or state change to check.

```typescript
// BAD — jest.fn() + toHaveBeenCalled on core flow
it('should throw when item is out of stock', async () => {
  const inventory = { check: jest.fn().mockResolvedValue(false) };
  const payment = { charge: jest.fn() };
  const sut = new OrderService(inventory, payment);

  await expect(sut.process(order)).rejects.toThrow(OutOfStockError);

  expect(payment.charge).not.toHaveBeenCalled();       // over-specification!
  expect(inventory.check).toHaveBeenCalledWith('sku-1'); // redundant!
});

// GOOD — plain stubs, assert the outcome
it('should throw when item is out of stock', async () => {
  const sut = createSUT({
    inventory: { check: async () => false },
  });

  await expect(sut.process(order)).rejects.toThrow(OutOfStockError);
});
```

The bad example uses `jest.fn()` for both dependencies — but only because it wants to verify calls, not because it needs call tracking. `payment.charge` doesn't need to be a spy; the test doesn't even configure a return value. And `not.toHaveBeenCalled()` breaks if a future refactor pre-authorizes charges and reverses them on failure.

```typescript
// BAD — spying on the happy path
it('should return order total with tax', async () => {
  const inventory = { check: jest.fn().mockResolvedValue(true) };
  const tax = { calculate: jest.fn().mockReturnValue(10) };
  const sut = new OrderService(inventory, tax);

  const result = await sut.process(order);

  expect(result.total).toBe(110);
  expect(tax.calculate).toHaveBeenCalledWith(100);  // redundant!
  expect(tax.calculate).toHaveBeenCalledTimes(1);   // redundant!
});

// GOOD — the return value IS the proof
it('should return order total with tax', async () => {
  const sut = createSUT({
    inventory: { check: async () => true },
    tax: { calculate: () => 10 },
  });

  const result = await sut.process(order);

  expect(result.total).toBe(110);
});
```

If `result.total` is 110, the SUT *must* have called tax correctly — the return value proves it. The good example also uses plain functions instead of `jest.fn()`, which makes it impossible to accidentally add call assertions later.

**The `createSUT` + `jest.fn()` trap**: When building a `createSUT` helper for a service with many dependencies, it's tempting to use `jest.fn()` for every collaborator so tests can call `.mockReturnValue()`. This pulls you into HOW-testing — once `jest.fn()` is available, `.toHaveBeenCalledWith()` is one keystroke away. Instead, default every collaborator to a plain object and let tests override by passing a new plain object:

```typescript
// GOOD — plain defaults, override with plain objects
// Even async collaborators use plain async functions — no jest.fn() needed!
// Tests override by passing a new plain object, not by calling .mockResolvedValue()
function createSUT(overrides: Partial<Deps> = {}) {
  return new Service(
    overrides.pricing    ?? { calculate: () => [{ desc: 'Fee', amount: 100 }] },
    overrides.payment    ?? { charge: async () => ({ txId: 'tx-1' }) },
    overrides.repo       ?? { save: async () => 'inv-1' },
    overrides.notify     ?? { send: async () => {} },  // or jest.fn() ONLY here
  );
}

// Per-test: override only what matters, with a NEW plain object
it('returns failure when payment throws', async () => {
  const sut = createSUT({
    payment: { charge: async () => { throw new Error('declined'); } },
  });
  const result = await sut.process(order);
  expect(result).toEqual({ success: false, error: 'Payment failed: declined' });
});

// BAD — jest.fn() for everything, invites .toHaveBeenCalledWith()
function createSUT() {
  const pricing = { calculate: jest.fn() };
  const payment = { charge: jest.fn() };
  // ... now every test does pricing.calculate.mockReturnValue(...)
  // ... and eventually someone adds expect(payment.charge).toHaveBeenCalledWith(...)
}

// ALSO BAD — returning a "bundle" of jest.fn() stubs
function makeSut() {
  const pricing = { calculate: jest.fn().mockReturnValue(defaultItems) };
  const payment = { charge: jest.fn().mockResolvedValue({ txId: 'tx-1' }) };
  return { sut: new Service(pricing, payment, ...), pricing, payment };
}
// Tests then use jest.spyOn() or .mockResolvedValue() to override — same trap
```

## Don't Mock Data Objects

Data objects (plain interfaces with properties, type aliases, DTOs) carry state — they don't have independent business logic that could fail. Mock *behavioral collaborators* (services, repositories, gateways), not *data carriers*.

TypeScript's structural typing makes this almost free: a plain object literal `{ id: '1', total: 99 }` satisfies an interface directly — no constructor, no factory, no mock library. The anti-pattern is reaching for mock utilities when a literal works.

```typescript
// BAD — mock library for a data object
import { mock } from 'jest-mock-extended';

it('should process the order', async () => {
  const order = mock<Order>();
  order.items = [item];
  order.total = 99;
  // order.customerId is undefined — mock<Order>() doesn't enforce required fields!

  const sut = createSUT();
  await sut.process(order);
});

// ALSO BAD — as-casting to avoid constructing real data
it('should process the order', async () => {
  const order = { items: [item] } as unknown as Order;
  // total, customerId, status are all missing — no type error thanks to the cast

  const sut = createSUT();
  await sut.process(order);
});

// GOOD — plain object literal, type-checked
it('should process the order', async () => {
  const order: Order = { id: 'ord-1', items: [item], total: 99, status: 'pending' };

  const sut = createSUT({
    fraudService: { check: async () => ({ isFlagged: false }) },
    shippingService: { createLabel: async () => ({ tracking: 'TRACK-123' }) },
  });

  const result = await sut.process(order);

  expect(result.success).toBe(true);
  expect(result.tracking).toBe('TRACK-123');
  expect(order.status).toBe('confirmed');  // direct state check
});
```

The `as unknown as Order` cast is especially insidious — it silences TypeScript completely, so missing or wrongly-typed fields don't produce errors. If the `Order` type adds a required field, tests with casts keep compiling while tests with typed literals correctly fail.

Use `Partial<T>` + spread for test data variations:

```typescript
const baseOrder: Order = { id: 'ord-1', items: [item], total: 99, status: 'pending' };

// Each test varies only what matters
const largeOrder: Order = { ...baseOrder, total: 10000 };
const emptyOrder: Order = { ...baseOrder, items: [] };
```

The rule of thumb: if a type is primarily properties (an interface or type alias), use a plain object literal with a type annotation so the compiler checks completeness. If it makes network calls or encapsulates complex behavior, stub it via the `createSUT` pattern.

## Factory Function DI Pattern (Module-Level Services)

This project uses factory functions instead of classes for services. The pattern avoids `vi.mock()` entirely by making dependencies explicit arguments.

**Service definition:**

```typescript
// Declare the dependency surface with Pick<> to minimize coupling to Prisma
export interface ReconciliationServiceDeps {
  prisma: Pick<typeof prisma, 'capitalEvent' | 'trade'>;
}

// Factory accepts overrides; production deps are the default
export function createReconciliationService(overrides: Partial<ReconciliationServiceDeps> = {}) {
  const deps = { ...productionDeps, ...overrides };
  return {
    async reconcileImportedEvents(accountId: string): Promise<void> {
      const events = await deps.prisma.capitalEvent.findMany({ where: { accountId } });
      // ...
    },
  };
}

// Backward-compatible default export — callers that don't need DI just import this
export const ReconciliationService = createReconciliationService();
```

**Test helpers:**

```typescript
// createSUT bundles the SUT with its stubs for inspection
function createSUT(overrides: Partial<ReconciliationServiceDeps> = {}) {
  const stubs = createStubs();
  return {
    sut: createReconciliationService({ prisma: stubs.prisma, ...overrides }),
    stubs,
  };
}

// vi.fn() IS correct here — async DB ops need .mockResolvedValue() per test
function createStubs() {
  return {
    prisma: {
      capitalEvent: {
        findMany: vi.fn().mockResolvedValue([]),
        delete: vi.fn().mockResolvedValue({}),
        update: vi.fn().mockResolvedValue({}),
      },
      trade: {
        findMany: vi.fn().mockResolvedValue([]),
        create: vi.fn().mockResolvedValue({}),
        update: vi.fn().mockResolvedValue({}),
      },
    },
  };
}

// Per-test usage: override only what the test cares about
it('should create a trade for each BUY event', async () => {
  const { sut, stubs } = createSUT();
  stubs.prisma.capitalEvent.findMany.mockResolvedValue([buyEvent]);

  await sut.reconcileImportedEvents('acc-1');

  // Assert on outcome — trade count in DB — not on how it got there
  expect(stubs.prisma.trade.create).toHaveBeenCalledTimes(1);
});
```

**When to use `vi.fn()` vs plain stubs:**

| Dependency type | Tool | Reason |
|---|---|---|
| Async I/O (DB, HTTP) | `vi.fn()` | Need `.mockResolvedValue()` to configure per-test return values |
| Synchronous pure logic | plain function | `{ method: () => value }` — no call tracking needed |
| Fire-and-forget side effects | `vi.fn()` | Verifying the call IS the test |

**Key rule:** `vi.fn()` for async I/O stubs is a narrow exception — it applies when the SAME stub method needs DIFFERENT return values across many tests AND the method lives in a complex object (like Prisma with many CRUD methods) where passing a new object each time is impractical. For services with simple 1-method interfaces (e.g., `PaymentGateway.charge`, `InvoiceRepository.save`), use `createSUT` with Partial overrides and plain async stubs instead — tests override by passing a new `{ charge: async () => ... }` object, no `jest.fn()` needed.

> See `src/features/ingest/__tests__/reconciliation.service.test.ts` in the trading-journal project for a full exemplar.

## Guidelines

- **Define interfaces for dependencies**, even where duck typing works. Explicit interfaces make the essential contract visible and make stubs type-safe.
- **`createSUT()` with `Partial` overrides and plain defaults**: Default every collaborator to a plain function stub (`{ method: async () => value }`), not `jest.fn()`. Override per test by passing a new plain object — not by calling `.mockReturnValue()`. This keeps `jest.fn()` out of core flow entirely. For complex SUTs with 5+ dependencies, this means each test overrides only the 1-2 collaborators it cares about; the rest use sensible defaults that are invisible to the test.
- **Plain stubs over `jest.fn()` / `vi.fn()`**: If you only need a return value, use a plain function: `{ check: async () => true }`. Using `jest.fn()` when you don't need call tracking invites unnecessary `.toHaveBeenCalledWith()` assertions. Reserve `jest.fn()` for fire-and-forget side effects where verifying the call *is* the test.
- **Avoid `jest.spyOn()` for core flow**: Spying on methods to verify they were called tests HOW, not WHAT. If you need to control a method's return value, inject a stub instead.
- **Immutable data as plain objects**: TypeScript interfaces with `readonly` fields are facts — use real instances, not mocks.
- **`AsyncLocalStorage` in tests**: Set up ambient context via `storage.run(testCtx, () => { ... })` in the test's setup phase.
