# Java: Essential vs Incidental Data

## Ambient Mechanism: ThreadLocal + Reader/Writer Interfaces

Java's `ThreadLocal` provides thread-scoped storage. Wrap it in reader/writer interfaces to maintain encapsulation and testability.

## Anti-Pattern

```java
// Logging/security data pollutes the IO layer API
public interface BankingClient {
    List<Account> getAccounts(BankId bankId, AccountId accountId,
        User user, HttpServletRequest request);  // incidental
}
```

This couples the IO layer to the application's User class and the Servlet API, destroying reusability across applications or in non-web contexts (batch jobs, CLI tools, daemons).

## Pattern: ThreadLocal with Encapsulated Reader/Writer

```java
// Writer interface — used only at the request boundary
public interface InvocationDataWriter {
    void write(InvocationData data);
}

// Reader interface — used anywhere incidental data is needed
public interface InvocationDataReader {
    InvocationData read(); // returns immutable snapshot
}

// Implementation encapsulates ThreadLocal
public class ThreadLocalInvocationDataStore
    implements InvocationDataReader, InvocationDataWriter {
    private final ThreadLocal<InvocationData> store = new ThreadLocal<>();

    public void write(InvocationData data) { store.set(data); }
    public InvocationData read() { return store.get(); }
    public void clear() { store.remove(); }
}

// Clean API — only essential data
public interface BankingClient {
    List<Account> getAccounts(BankId bankId, AccountId accountId);
}
```

## Event Handlers for Incidental Concerns

After fixing the interface, a natural first-draft implementation looks like this:

```java
// ❌ STILL WRONG — fixes the method signature but not the implementation
public class BankingClientImpl implements BankingClient {
    private final BankHostGateway gateway;
    private final AuditLogger auditLogger;        // ❌ incidental constructor dependency
    private final AuditContextReader auditContext; // ❌ incidental constructor dependency

    @Override
    public List<Account> getAccounts(BankId bankId, AccountId accountId) {
        List<Account> accounts = gateway.fetchAccounts(bankId, accountId);
        auditLogger.log(AuditEvent.accountsFetched(bankId, accountId, auditContext.read())); // ❌ inline
        return accounts;
    }
}
```

This still violates the principle. `BankingClientImpl` now depends on `AuditLogger` — an incidental concern it doesn't own. Adding analytics means changing `BankingClientImpl`. The implementation should know **nothing** about logging, audit, or tracing.

The method signature is essential-only, but **incidental dependencies belong nowhere in the implementation** — not as method params, not as constructor args. The implementation should only announce *what happened*; a separate handler decides *what to do about it*.

**Pattern — event handler (implementation announces, handler decides):**
```java
public class BankingClientImpl implements BankingClient {

    // Nested interface: BankingClientImpl owns its event vocabulary
    public interface EventHandler {
        void accountsFetched(BankId bankId, AccountId accountId, List<Account> accounts);
        void accountsFetchFailed(BankId bankId, AccountId accountId, BankHostException e);
    }

    private final BankHostGateway gateway;
    private final EventHandler eventHandler;    // ✅ the only incidental dependency

    public BankingClientImpl(BankHostGateway gateway, EventHandler eventHandler) {
        this.gateway = gateway;
        this.eventHandler = eventHandler;
    }

    @Override
    public List<Account> getAccounts(BankId bankId, AccountId accountId) {
        try {
            List<Account> accounts = gateway.fetchAccounts(bankId, accountId);
            eventHandler.accountsFetched(bankId, accountId, accounts); // announces fact
            return accounts;
        } catch (BankHostException e) {
            eventHandler.accountsFetchFailed(bankId, accountId, e);
            throw e;
        }
    }
}
```

`BankingClientImpl` knows **nothing** about logging, audit, or `InvocationData`. It only fires events.

**EventHandler implementation — lives in the application layer, reads ambient context:**
```java
public class AuditLoggingEventHandler implements BankingClientImpl.EventHandler {
    private final InvocationDataReader invocationData;
    private final AuditLogger auditLogger;

    @Override
    public void accountsFetched(BankId bankId, AccountId accountId, List<Account> accounts) {
        InvocationData ctx = invocationData.read();   // reads ambient context here
        auditLogger.log(AuditEvent.success(bankId, accountId, accounts.size(), ctx));
    }

    @Override
    public void accountsFetchFailed(BankId bankId, AccountId accountId, BankHostException e) {
        InvocationData ctx = invocationData.read();
        auditLogger.log(AuditEvent.failure(bankId, accountId, e, ctx));
    }
}
```

**Why this matters:** adding analytics means adding another `EventHandler` implementation or composing them — zero changes to `BankingClientImpl`. In tests, pass a no-op `EventHandler`. In batch jobs, pass a different handler. The IO layer is fully reusable.

## Guidelines

- **ThreadLocal + thread pools**: When scheduling `Runnable` tasks on thread pools, wrap the runnable to transfer `InvocationData` from the scheduling thread to the executing thread. Override `ThreadPoolExecutor#beforeExecute` to write the data for the executing thread.
- **Java 21+ ScopedValues**: Prefer `ScopedValue` (JEP 446) over `ThreadLocal` when using virtual threads (Project Loom). Same principle, better semantics for structured concurrency.
- **Spring MDC**: For logging specifically, SLF4J's `MDC` (Mapped Diagnostic Context) is the standard ThreadLocal-backed mechanism for request-scoped log data.
- **Dependency injection**: Wire reader/writer interfaces via constructor injection. The DI container manages the shared storage instance.
