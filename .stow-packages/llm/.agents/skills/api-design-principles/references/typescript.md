# TypeScript/Node: Essential vs Incidental Data

## Ambient Mechanism: AsyncLocalStorage

Node.js provides `AsyncLocalStorage` for request-scoped data that persists across async boundaries without parameter passing.

## Anti-Pattern

```typescript
// Logging/tracing context pollutes every function signature
async function processOrder(
  orderId: string,
  userId: string,       // incidental: for logging
  requestId: string,    // incidental: for tracing
  logger: Logger        // incidental: for logging
): Promise<OrderResult> {
  logger.info({ requestId, userId, action: 'process_order' });
  return await fulfillOrder(orderId, userId, requestId, logger);
}

async function fulfillOrder(
  orderId: string,
  userId: string,       // just relaying
  requestId: string,    // just relaying
  logger: Logger        // just relaying
): Promise<OrderResult> {
  // userId, requestId, logger are not essential to fulfilling an order
}
```

## Pattern: AsyncLocalStorage for Incidental Data

```typescript
import { AsyncLocalStorage } from 'node:async_hooks';

interface RequestContext {
  readonly userId: string;
  readonly requestId: string;
}

const requestContext = new AsyncLocalStorage<RequestContext>();

// Writer: set once at the request boundary
function handleRequest(req: Request, handler: () => Promise<Response>) {
  const ctx: RequestContext = {
    userId: extractUserId(req),
    requestId: req.headers.get('x-request-id') ?? crypto.randomUUID(),
  };
  return requestContext.run(ctx, handler);
}

// Reader: access anywhere without parameters
function getRequestContext(): RequestContext {
  const ctx = requestContext.getStore();
  if (!ctx) throw new Error('No request context available');
  return ctx;
}

// Clean function signatures — only essential data
async function processOrder(orderId: string): Promise<OrderResult> {
  const { requestId, userId } = getRequestContext();
  logger.info({ requestId, userId, action: 'process_order' });
  return await fulfillOrder(orderId);
}

async function fulfillOrder(orderId: string): Promise<OrderResult> {
  // no incidental parameters — clean and reusable
}
```

## Guidelines

- **AsyncLocalStorage** is Node's equivalent of Java's ThreadLocal, but works across async/await boundaries.
- **Wrap in a getter function** (`getRequestContext()`) to encapsulate the mechanism. Consumers never see `AsyncLocalStorage` directly.
- **Make stored data immutable** — use `readonly` properties or `Readonly<T>`.
- **Set at the boundary**: middleware, request handler, or queue consumer entry point.
- In **NestJS/Express/Fastify**, middleware or interceptors set the context; services and repositories read it via the getter.
