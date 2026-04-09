# Ruby: Essential vs Incidental Data

## Ambient Mechanism: RequestStore / CurrentAttributes

Ruby's `Thread.current` provides thread-local storage. The `request_store` gem and Rails' `CurrentAttributes` provide request-scoped storage that auto-clears between requests.

## Anti-Pattern

```ruby
# Request context pollutes service method signatures
class PaymentService
  def process_payment(payment_id, current_user:, ip_address:, request_id:)
    Rails.logger.info("Processing #{payment_id} for user #{current_user.id}")
    gateway.charge(payment_id, current_user:, ip_address:, request_id:)
  end
end
```

## Pattern: CurrentAttributes / RequestStore for Incidental Data

```ruby
# Rails CurrentAttributes — set at the boundary
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :request_id, :ip_address
end

class ApplicationController < ActionController::Base
  before_action :set_current_context

  private

  def set_current_context
    Current.user = current_user
    Current.request_id = request.request_id
    Current.ip_address = request.remote_ip
  end
end

# Clean method signatures — only essential data
class PaymentService
  def process_payment(payment_id)
    Rails.logger.info("Processing #{payment_id} for user #{Current.user.id}")
    gateway.charge(payment_id)
  end
end
```

## Guidelines

- **`ActiveSupport::CurrentAttributes`** (Rails 5.2+) is the idiomatic Rails solution. It auto-resets between requests and provides a clean class-level API.
- **`request_store` gem** is the alternative for non-Rails apps or when you need more control. It auto-clears between requests, preventing data leakage in threaded servers (Puma).
- **Freeze stored values** or use immutable value objects to prevent mutation.
- **Encapsulate access** in a class or module method, not raw `Thread.current[:key]` lookups scattered through code.
