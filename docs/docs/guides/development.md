---
title: Development Guide
description: Coding conventions, practices, and guidelines for Tutor Nexus.
sidebar_position: 2
---

This guide covers coding conventions, project structure, and development workflows.

## Project Structure

```
tutornexus/
├── apps/
│   ├── api/           # Cloudflare Workers API (Hono + OpenAPI)
│   └── web/            # React frontend
├── services/
│   ├── mcp/           # Go MCP server
│   └── adapters/      # TypeScript adapter Workers
├── tools/
│   └── cli/           # Rust CLI
├── packages/          # Shared TypeScript packages
├── docs/              # Docusaurus documentation
├── d1/                # Database migrations
└── scripts/          # Utility scripts
```

## Coding Conventions

### TypeScript

```typescript
// Use explicit types for function parameters and returns
function getUserById(id: string): User | null {
  return db.users.find(u => u.id === id);
}

// Use interfaces for object shapes
interface Session {
  id: string;
  userId: string;
  title: string;
  status: SessionStatus;
  createdAt: Date;
  updatedAt: Date;
}

// Prefer const assertions for readonly data
const ADAPTERS = ['sfu', 'bcit', 'ubc'] as const;
```

### Go

```go
// Use error handling consistently
func (s *Server) HandleRequest(ctx context.Context, req Request) (*Response, error) {
  if err := req.Validate(); err != nil {
    return nil, fmt.Errorf("validation failed: %w", err)
  }
  
  result, err := s.service.Process(ctx, req)
  if err != nil {
    return nil, err
  }
  
  return &Response{Data: result}, nil
}

// Use structured logging
log.Info("processing request",
  zap.String("request_id", req.ID),
  zap.String("user_id", req.UserID),
)
```

### Rust

```rust
// Use Result types for fallible operations
fn parse_config(path: &Path) -> Result<Config, ConfigError> {
  let file = File::open(path)
    .context("failed to open config file")?;
  
  let config: Config = serde_yaml::from_reader(file)
    .context("failed to parse config YAML")?;
  
  Ok(config)
}

// Use anyhow for application errors
use anyhow::{Context, Result, bail};
```

## Git Workflow

### Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code style (formatting, no logic)
- `refactor` - Code restructuring
- `perf` - Performance improvements
- `test` - Adding or modifying tests
- `chore` - Build, CI, tooling
- `breaking` - Breaking change

**Examples:**
```
feat(api): add tn_transfer_resolve tool
fix(mcp): handle missing course references
docs(adr): update ADR-012 with error conventions
refactor(cli): simplify REPL input handling
```

### Branch Naming

```
feature/<issue-number>-<short-description>
bugfix/<issue-number>-<short-description>
docs/<short-description>
chore/<short-description>
```

### Pull Requests

1. Create a feature branch from `main`
2. Make changes following conventions
3. Run linting and tests locally
4. Open PR with description
5. Get required approvals
6. Squash and merge

## Testing

### TypeScript Tests

```bash
# Run all tests
pnpm test

# Run with coverage
pnpm test:coverage

# Watch mode
pnpm test:watch
```

### Go Tests

```bash
go test ./... -v
go test ./... -coverprofile=coverage.out
```

### Rust Tests

```bash
cargo test
cargo test --doc
```

## Linting

```bash
# TypeScript
pnpm lint
pnpm lint:fix

# Markdown
pnpm lint:markdown

# Commit messages
npx commitlint --from=main --to=HEAD
```

## Building

```bash
# Build all packages
pnpm build

# Build individual packages
pnpm build:api
pnpm build:web
pnpm build:cli
pnpm build:docs
```

## Development Tools

### Database Management

```bash
# Setup local database
pnpm db:setup

# Run migrations
pnpm db:migrate

# Push schema changes
pnpm db:push

# Open D1 console
pnpm db:console
```

### API Documentation

```bash
# Generate OpenAPI spec
pnpm api:generate

# Serve Swagger UI locally
pnpm api:docs
```

## Debugging

### Workers

```bash
# View logs
wrangler tail

# Viewtail in real-time
wrangler tail --project-name=tutor-nexus-api
```

### Database

```bash
# Query local database
wrangler d1 execute tutor-nexus-api --local --command="SELECT * FROM users LIMIT 10"
```

## Best Practices

### Performance

- Use Cloudflare Durable Objects for real-time state
- Cache expensive operations with KV
- Batch database queries where possible
- Use pagination for list endpoints

### Security

- Never commit secrets or API keys
- Use environment variables for credentials
- Validate all input with Zod schemas
- Use parameterized queries
- Implement rate limiting

### Documentation

- Document all public APIs
- Write docstrings for complex functions
- Keep ADRs up to date
- Add code comments for non-obvious logic

## See Also

- [Architecture Decisions](/docs/adrs)
- [API Reference](/docs/reference/api)
- [Deployment Guide](/docs/guides/deployment)
- [Testing Guide](/docs/guides/testing)
