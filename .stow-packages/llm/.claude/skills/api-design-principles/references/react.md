# React: Essential vs Incidental Data

## The Problem: Prop Drilling

Prop drilling is React's manifestation of parameter pollution. When a deeply nested component needs data from the top of the tree (current user, theme, locale, feature flags), passing it through every intermediate component pollutes their props with data they don't use.

## Anti-Pattern

```tsx
// Every intermediate component must accept and forward user
function App({ user }: { user: User }) {
  return <Dashboard user={user} />;
}

function Dashboard({ user }: { user: User }) {
  // Dashboard doesn't use user — it just relays it
  return <TransactionList user={user} />;
}

function TransactionList({ user }: { user: User }) {
  return <TransactionRow user={user} amount={100} />;
}
```

Adding analytics tracking would require threading an `analyticsClient` prop through every layer.

## Pattern: Context for Incidental, Props for Essential

```tsx
// Incidental data: provided via Context
const UserContext = createContext<User | null>(null);

// Custom hook encapsulates the mechanism (like a Reader interface)
function useCurrentUser(): User {
  const user = useContext(UserContext);
  if (!user) throw new Error('No UserContext provider');
  return user;
}

function App() {
  const user = useAuth();
  return (
    <UserContext.Provider value={user}>
      <Dashboard />
    </UserContext.Provider>
  );
}

// Dashboard has no user prop — it doesn't need one
function Dashboard() {
  return <TransactionList />;
}

// Only the component that *uses* the data accesses it
function TransactionRow({ amount }: { amount: number }) {
  const user = useCurrentUser(); // incidental: for logging/analytics
  // amount is essential to rendering a transaction row
  return <div>{amount}</div>;
}
```

## Guidelines

- **Props are for essential data**: data that defines *what* the component renders or *what* behavior it performs.
- **Context is for incidental data**: current user, theme, locale, feature flags, analytics clients, logger instances — data that many components may need but that doesn't define their core purpose.
- **Custom hooks encapsulate the mechanism**: Wrap `useContext` in a custom hook (e.g., `useCurrentUser()`) so consumers don't couple to the Context object directly. This is the React equivalent of the Reader interface pattern.
- **Don't over-contextualize**: If only a parent and its direct child share data, a prop is simpler. Context shines when data needs to skip layers.

## See Also

The `vercel-composition-patterns` skill covers the tactical React patterns for *structuring* components that use Context: compound components, explicit variants, and the `{ state, actions, meta }` context interface pattern. This skill covers the *principled question* of what belongs in Context (incidental data) vs props (essential data). Use both together: this skill decides *whether* data should use Context; `vercel-composition-patterns` decides *how* to structure the provider and consumer components.
