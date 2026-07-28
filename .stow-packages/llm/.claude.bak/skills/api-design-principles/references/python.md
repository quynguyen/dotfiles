# Python: Essential vs Incidental Data

## Ambient Mechanism: contextvars (Python 3.7+)

The `contextvars` module provides task-local storage that works with asyncio, threads, and synchronous code.

## Anti-Pattern

```python
# Request context threaded through every function
def process_order(order_id: str, user_id: str, request_id: str, logger) -> OrderResult:
    logger.info(f"Processing {order_id}", extra={"user_id": user_id, "request_id": request_id})
    return fulfill_order(order_id, user_id, request_id, logger)

def fulfill_order(order_id: str, user_id: str, request_id: str, logger) -> OrderResult:
    # user_id, request_id, logger are just passed through
    ...
```

## Pattern: contextvars for Incidental Data

```python
from contextvars import ContextVar
from dataclasses import dataclass

@dataclass(frozen=True)  # immutable
class RequestContext:
    user_id: str
    request_id: str

_request_ctx: ContextVar[RequestContext] = ContextVar('request_ctx')

# Writer — called at the boundary
def set_request_context(ctx: RequestContext) -> None:
    _request_ctx.set(ctx)

# Reader — called anywhere
def get_request_context() -> RequestContext:
    return _request_ctx.get()  # raises LookupError if not set

# Clean function signatures — only essential data
def process_order(order_id: str) -> OrderResult:
    ctx = get_request_context()  # incidental
    logger.info(f"Processing {order_id}", extra={"user_id": ctx.user_id})
    return fulfill_order(order_id)

def fulfill_order(order_id: str) -> OrderResult:
    # no incidental params — clean and reusable
    ...
```

## Framework Integration

```python
# FastAPI middleware
@app.middleware("http")
async def inject_context(request: Request, call_next):
    ctx = RequestContext(
        user_id=request.state.user_id,
        request_id=request.headers.get("x-request-id", str(uuid4())),
    )
    set_request_context(ctx)
    return await call_next(request)

# Django middleware
class RequestContextMiddleware:
    def __call__(self, request):
        set_request_context(RequestContext(
            user_id=getattr(request, 'user_id', 'anonymous'),
            request_id=request.META.get('HTTP_X_REQUEST_ID', str(uuid4())),
        ))
        return self.get_response(request)
```

## Guidelines

- **`contextvars` works with asyncio**: Each async task gets its own copy, preventing cross-request data leakage.
- **Use `frozen=True` dataclasses** for context data to enforce immutability.
- **Wrap access in functions** (`get_request_context()`), not raw `ContextVar.get()` calls scattered through code.
- **structlog** integrates naturally: bind context vars to the logger at the middleware level for automatic inclusion in all log entries.
