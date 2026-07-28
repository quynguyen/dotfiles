# React Unit Testing

## Framework: React Testing Library + Jest/Vitest

React Testing Library embodies the "verify outcomes, not interactions" principle. It tests what users see and do, not component internals.

## Hooks Look Like Behavioral Collaborators — They Aren't

This is the most common React testing mistake. When a component uses `useAuth()` and `useProduct()`, the instinct is to mock them — they "have network/context logic that can fail independently." That reasoning is wrong, and applying it produces brittle tests.

**Start here. This test is wrong:**

```tsx
// You rename useProduct → useProductQuery (pure refactor, zero behavior change).
// This test now fails. The component still works. The test lied.
jest.mock('./hooks/useProduct')
jest.mock('./hooks/useAuth')
```

The failure: you refactored the hook name, not the behavior. A test that breaks on a valid refactor is measuring HOW, not WHAT. That is the definition of a bad test in Quy's framework.

**Why the "behavioral collaborator" framing is wrong for hooks:**

In backend code, a behavioral collaborator is something you inject — a repository, a service, an email sender. You can swap the real implementation for a test double because the constructor/function accepts the dependency.

React doesn't allow this for hooks. **Different hook implementations have different numbers of internal `useState`/`useEffect` calls.** You cannot swap `useProduct` for a test double at the injection point because there is no injection point — React's hook ordering invariant prevents it. This is not an oversight; it's by design.

When there is no injection point, there is no seam at the hook boundary. Mocking a hook doesn't use a seam — it bypasses the code entirely. The test runs a component that has never actually touched its real data-fetching or auth logic.

**Rebutting the isolation argument:**

"Bugs in hooks don't cascade into component tests." — This sounds right but reverses the goal. If `useProduct` transforms data incorrectly, your component test *should* catch it — the hook is part of the component's implementation, not an independent service. Isolating the component from its own data-fetching logic isn't unit isolation; it's testing a shell.

### React's actual seams — use these instead

React provides two designed-in injection points:

**Context** — for incidental/ambient data (auth, theme, locale). The hook (`useAuth`, `useTheme`) is the *reader*; the Context is the *mechanism*. Set the mechanism; let the reader run.

**The network** — for essential fetched data (`useProduct`, `useOrders`, `useQuery`). The endpoint is the interface; the hook is the implementation. Mock the endpoint (msw); let the hook run.

### Type 1 — Context-reading hooks (`useAuth`, `useTheme`, `useLocale`)

```tsx
// BAD — mocks the reader, skips the mechanism
jest.mock('./hooks/useAuth')
mockUseAuth.mockReturnValue({ user: adminUser })

// This test passes even if AuthContext is wired wrong in your app.
// It also breaks if you rename useAuth → useCurrentUser.

// GOOD — set the ambient context, let the real hook read from it
function renderWithProviders(ui, { user = defaultTestUser, ...opts } = {}) {
  return render(
    <AuthContext.Provider value={user}>{ui}</AuthContext.Provider>,
    opts
  );
}

it('shows admin controls for admin users', () => {
  renderWithProviders(<Dashboard />, { user: adminUser });
  expect(screen.getByRole('button', { name: /delete/i })).toBeInTheDocument();
});
```

Rename `useAuth` to `useCurrentUser`, restructure context internals — this test doesn't care. It tests that the component responds correctly to the context value, which is the actual contract.

### Type 2 — Data-fetching hooks (`useProduct`, `useOrders`, `useQuery`)

```tsx
// BAD — mocks the hook, couples to name and return shape
jest.mock('./hooks/useProduct')
mockUseProduct.mockReturnValue({ product: PRODUCT, isLoading: false })

// Rename the hook, switch to React Query, add caching — test breaks.
// Component behavior didn't change. Test is wrong.

// GOOD — mock the network endpoint, let the real hook run
const server = setupServer(
  http.get('/api/products/:id', () =>
    HttpResponse.json({ id: 'p1', name: 'Wireless Headphones', category: 'Electronics' })
  ),
  http.post('/api/reviews', () => HttpResponse.json({ id: 'r1' }))
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

it('shows product name after loading', async () => {
  render(<ProductReviewForm productId="p1" onReviewSubmitted={jest.fn()} />);
  expect(await screen.findByRole('heading', { name: /Review: Wireless Headphones/i }))
    .toBeInTheDocument();
});

// Override for specific scenarios (loading state, errors):
it('shows loading state while product is being fetched', () => {
  server.use(
    http.get('/api/products/:id', () => new Promise(() => {})) // never resolves
  );
  render(<ProductReviewForm productId="p1" onReviewSubmitted={jest.fn()} />);
  expect(screen.getByText('Loading product...')).toBeInTheDocument();
});
```

Switch from a custom hook to React Query, rename the hook, add SWR caching — the msw test is unchanged. The component still shows the same data; the test still passes.

---

## Anti-Pattern: Testing Implementation Details

```tsx
// BAD: Testing internal state and method calls
it('updates internal state when clicked', () => {
  const wrapper = shallow(<Counter />);
  wrapper.instance().handleClick();
  expect(wrapper.state('count')).toBe(1);
});
```

This test breaks if you rename `handleClick`, switch from class to function component, or restructure internal state — none of which change user-visible behavior.

## Pattern: Test Behavior, Not Implementation

```tsx
// GOOD: Testing what the user sees
it('should increment the displayed count when clicked', async () => {
  render(<Counter initialCount={0} />);
  await userEvent.click(screen.getByRole('button', { name: /increment/i }));
  expect(screen.getByText('1')).toBeInTheDocument();
});
```

## Where WHAT-Testing Gets Subtle in React

### Callback props — the one place `jest.fn()` is right

Unlike backend code where `jest.fn()` is a HOW trap (see TypeScript reference), callback props are a component's *output mechanism*. When a `<Form>` calls `onSubmit(data)`, that invocation is the observable outcome — the component's contract with its parent.

```tsx
// GOOD — callback invocation IS the outcome
it('should submit the form data when user clicks submit', async () => {
  const onSubmit = jest.fn();
  renderWithProviders(<CheckoutForm onSubmit={onSubmit} />);

  await userEvent.type(screen.getByLabelText(/name/i), 'Alice');
  await userEvent.click(screen.getByRole('button', { name: /submit/i }));

  expect(onSubmit).toHaveBeenCalledWith(expect.objectContaining({ name: 'Alice' }));
});
```

### Mocking child components — HOW

```tsx
// BAD — couples test to which child component is used
jest.mock('./PriceDisplay', () => ({ price }: Props) => <span>{price}</span>);
```

If you refactor `OrderSummary` to inline the price or swap `PriceDisplay` for `FormattedCurrency`, this test breaks — even though the user still sees "$42.00". Let child components render naturally and assert on what the user sees.

### Snapshot testing — HOW

```tsx
// BAD — locks in DOM structure
expect(container).toMatchSnapshot();
```

Snapshots break on any structural change — wrapping in a `<div>`, reordering elements, changing class names — none of which affect user-visible behavior. Test specific user-visible outcomes instead.

## Don't Mock Data Objects

Props, state objects, and API response data are just JavaScript objects — use plain literals.

```tsx
// BAD — jest.fn() for data, invites pointless toHaveBeenCalled assertions
const mockUser = jest.fn().mockReturnValue({ id: '1', name: 'Alice', role: 'admin' });

// GOOD — plain object
const adminUser: User = { id: '1', name: 'Alice', role: 'admin' };
```

## Guidelines

- **`renderWithProviders()` with defaults** = the React `createSUT()`. Add context providers with sensible defaults; override only what each test needs.
- **`screen.getByRole` over `getByTestId`**: Query by role — tests what users and assistive technology see.
- **Don't mock hooks**: Hooks are readers of React's actual seams (Context and network), not seams themselves. For context-reading hooks (`useAuth`): populate the context via a Provider. For data-fetching hooks (`useProduct`): mock the API endpoint with msw and let the real hook run.
- **Mock at the network boundary**: Use `msw` for fetch interception. `jest.spyOn(global, 'fetch')` couples tests to the fetch call site — the same refactor-fragility problem as mocking hooks.
- **`findBy*` for async data**: After msw, data loads asynchronously. Use `await screen.findByRole(...)` not `getByRole(...)` for anything that appears after a network response.
- **`userEvent` over `fireEvent`**: `userEvent.setup()` simulates real browser input sequences; `fireEvent` dispatches raw DOM events.
- **Let child components render naturally**: Don't `jest.mock()` child components. Render the full subtree and assert on what the user sees.

## See Also

The `vercel-composition-patterns` skill covers compound components and provider patterns. `renderWithProviders()` is especially important there — it supplies the provider context (incidental data) with sensible defaults. The `api-design-principles` skill covers *why* certain data belongs in providers vs props.
