---
title: Testing Guide
description: Testing strategy and guidelines for Tutor Nexus.
sidebar_position: 4
---

## Testing Philosophy

We follow a multi-layered testing strategy:

1. **Unit Tests** - Fast, isolated component testing
2. **Integration Tests** - API and database interaction testing
3. **E2E Tests** - Full workflow validation
4. **Contract Tests** - API schema compliance

## Test Structure

```
apps/api/
├── src/
│   └── routes/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── setup.ts
apps/web/
├── src/
├── tests/
└── setup.ts
services/mcp/
├── server/
└── *_test.go
tools/cli/
├── src/
└── tests/
```

## Unit Testing

### TypeScript (Vitest)

```bash
# Run unit tests
pnpm test:unit

# Watch mode
pnpm test:unit:watch

# Coverage report
pnpm test:unit:coverage
```

**Example test:**

```typescript
// apps/api/tests/unit/sessions.test.ts
import { describe, it, expect, vi } from 'vitest';
import { createSession, getSession } from '../src/routes/sessions';

describe('Session Routes', () => {
  it('should create a new session', async () => {
    const mockDb = {
      insert: vi.fn().mockResolvedValue({ id: 'test-id' })
    };
    
    const session = await createSession({
      title: 'Test Session',
      userId: 'user-123',
    }, mockDb);
    
    expect(session.id).toBeDefined();
    expect(mockDb.insert).toHaveBeenCalledOnce();
  });
});
```

### Go

```bash
go test ./... -v -count=1
go test ./... -coverprofile=coverage.out
```

**Example test:**

```go
// services/mcp/server/sessions_test.go
func TestSessionCreation(t *testing.T) {
  server := NewTestServer(t)
  
  session, err := server.CreateSession(context.Background(), &CreateSessionRequest{
    Title: "Test Session",
  })
  
  assert.NoError(t, err)
  assert.NotEmpty(t, session.ID)
}
```

### Rust

```bash
cargo test
cargo test --doc
```

## Integration Testing

### API Integration Tests

```bash
# Run integration tests
pnpm test:integration
```

**Example:**

```typescript
// apps/api/tests/integration/api.test.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Hono } from 'hono';
import { testClient } from 'hono/testing';

describe('API Integration Tests', () => {
  let app: Hono;
  
  beforeAll(() => {
    app = createApp();
  });
  
  it('should return health check', async () => {
    const res = await testClient(app).health.$get();
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.status).toBe('healthy');
  });
});
```

### Database Integration

```typescript
// apps/api/tests/setup.ts
import { D1Database } from '@cloudflare/workers-types';

export async function setupTestDatabase(): Promise<D1Database> {
  // Create in-memory D1 for testing
  const db = createMockD1();
  
  // Run migrations
  await applyMigrations(db);
  
  return db;
}
```

## E2E Testing

### Playwright

```bash
# Install Playwright
pnpm exec playwright install

# Run E2E tests
pnpm test:e2e

# UI mode
pnpm test:e2e:ui
```

**Example test:**

```typescript
// apps/web/tests/e2e/session.spec.ts
import { test, expect } from '@playwright/test';

test('user can create a tutoring session', async ({ page }) => {
  await page.goto('/dashboard');
  
  await page.click('button:has-text("New Session")');
  await page.fill('input[name="title"]', 'Math Help - Calculus');
  await page.click('button:has-text("Create")');
  
  await expect(page).toHaveURL(/\/session\/[a-zA-Z0-9]+/);
  await expect(page.locator('h1')).toContainText('Math Help');
});
```

## Contract Testing

### OpenAPI Validation

```bash
# Validate API spec
pnpm test:contract
```

The API must conform to the OpenAPI specification defined in `apps/api/src/openapi.yaml`.

## Test Coverage Requirements

| Metric | Minimum | Target |
|--------|---------|--------|
| Unit Tests | 70% | 85% |
| Integration Tests | 50% | 70% |
| E2E Tests | Critical paths | All user flows |
| API Coverage | 100% endpoints | 100% endpoints |

## Mocking

### API Mocks

```typescript
// Use MSW for API mocking
import { setupWorker, rest } from 'msw';

const handlers = [
  rest.get('/api/sessions', (req, res, ctx) => {
    return res(
      ctx.json({
        sessions: [],
        pagination: { page: 1, limit: 10 },
      })
    );
  }),
];

setupWorker(...handlers);
```

### Database Mocks

```typescript
// Create mock D1 for unit tests
export function createMockD1(): D1Database {
  return {
    prepare: vi.fn().mockReturnThis(),
    bind: vi.fn().mockReturnThis(),
    first: vi.fn(),
    all: vi.fn(),
    run: vi.fn().mockResolvedValue({ success: true }),
  } as unknown as D1Database;
}
```

## Continuous Integration

Tests run automatically in CI:

```yaml
# .github/workflows/test.yml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: pnpm install
      - run: pnpm lint
      - run: pnpm typecheck
      - run: pnpm test:unit
      - run: pnpm test:integration
```

## Best Practices

1. **Write tests before code** (TDD when appropriate)
2. **Keep tests independent** - no shared state
3. **Use meaningful test names** - describe behavior
4. **Test edge cases** - empty inputs, errors, boundaries
5. **Avoid implementation details** - test behavior, not implementation
6. **Mock external dependencies** - APIs, databases
7. **Run tests locally before pushing**
8. **Fix tests when changing behavior** - not when refactoring

## See Also

- [Vitest Documentation](https://vitest.dev/)
- [Playwright Documentation](https://playwright.dev/)
- [Go Testing](https://pkg.go.dev/testing)
- [Rust Testing](https://doc.rust-lang.org/book/ch11-00-testing.html)
