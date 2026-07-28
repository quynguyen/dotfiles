# Elixir: Essential vs Incidental Data

## Ambient Mechanism: Process Dictionary / Logger.metadata

Elixir's process-per-request model naturally isolates request-scoped data. Incidental data can live in `Logger.metadata` (for logging) or the process dictionary (for other concerns).

## Anti-Pattern

```elixir
# Request context threaded through every function
def process_order(order_id, user_id, request_id) do
  Logger.info("Processing #{order_id}",
    user_id: user_id, request_id: request_id)
  fulfill_order(order_id, user_id, request_id)
end

def fulfill_order(order_id, user_id, request_id) do
  # user_id and request_id are just passed through
  ...
end
```

## Pattern: Logger.metadata + Process Dictionary

```elixir
# Set at the Plug/Phoenix pipeline level
defmodule MyApp.RequestContextPlug do
  def call(conn, _opts) do
    Logger.metadata(
      user_id: conn.assigns[:current_user].id,
      request_id: conn.assigns[:request_id]
    )
    # Logger.metadata is process-scoped, auto-included in all log output
    conn
  end
end

# Clean function signatures — only essential data
def process_order(order_id) do
  Logger.info("Processing order #{order_id}")
  # user_id and request_id automatically included by Logger
  fulfill_order(order_id)
end
```

## For Non-Logging Incidental Data

```elixir
# When incidental data is needed beyond logging, use process dictionary
defmodule MyApp.RequestContext do
  def set(context) do
    Process.put(:request_context, context)
  end

  def get do
    Process.get(:request_context) ||
      raise "No request context set for this process"
  end
end
```

## Guidelines

- **Elixir's process model is an advantage**: Each request runs in its own process, so process-scoped data is naturally request-scoped. No thread-safety concerns.
- **Logger.metadata** is the idiomatic solution for logging context — it auto-attaches metadata to every log message from that process.
- **Process dictionary** is generally discouraged in Elixir for general state, but is acceptable for request-scoped incidental data — it's analogous to ThreadLocal in Java.
- **For spawned Tasks**: `Task.async` inherits the caller's group leader for Logger but not the process dictionary. Explicitly pass context to spawned processes when needed.
- **Telemetry**: Use `:telemetry.span/3` with metadata for observability concerns rather than manual logging.
