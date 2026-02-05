# Contributing to Tutor Nexus

Thank you for your interest in contributing to Tutor Nexus! This guide will help you get started.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Development Setup](#development-setup)
3. [Project Structure](#project-structure)
4. [Coding Standards](#coding-standards)
5. [Testing Requirements](#testing-requirements)
6. [Submitting Changes](#submitting-changes)
7. [Code Review Process](#code-review-process)
8. [Community](#community)

---

## Getting Started

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Git | Latest | Version control |
| Node.js | 20+ | TypeScript runtime |
| Go | 1.25+ | MCP server |
| Rust | Latest | CLI tool |
| pnpm | 9+ | Package manager |
| wrangler | Latest | Cloudflare CLI |
| Docker | Latest | Database (optional) |

### Setting Up Your Environment

```bash
# 1. Fork the repository
#    Go to https://github.com/eschmechel/tutornexus
#    Click "Fork" button

# 2. Clone your fork
git clone https://github.com/YOUR-USERNAME/tutornexus
cd tutornexus

# 3. Add upstream remote
git remote add upstream https://github.com/eschmechel/tutornexus.git

# 4. Install pnpm
npm install -g pnpm@9

# 5. Install dependencies
pnpm install

# 6. Set up git hooks
pnpm prepare

# 7. Copy environment template
cp .env.example .env
```

### Creating a Development Branch

```bash
# Sync with upstream
git fetch upstream
git checkout main
git merge upstream/main

# Create feature branch
git checkout -b feature/your-feature-name
```

---

## Development Setup

### Cloudflare Setup

```bash
# 1. Login to Cloudflare
wrangler login

# 2. Create development databases
wrangler d1 create tn-sessions --env development
wrangler d1 create tn-courses --env development
wrangler d1 create tn-transfers --env development

# 3. Update wrangler.toml with database IDs
#    (IDs are returned from create commands)

# 4. Run migrations
wrangler d1 execute tn-sessions --file=d1/migrations/001_initial.sql --local
wrangler d1 execute tn-courses --file=d1/migrations/002_courses.sql --local
wrangler d1 execute tn-transfers --file=d1/migrations/003_transfers.sql --local
```

### Running Development Servers

```bash
# Terminal 1: Start API
pnpm --filter api dev

# Terminal 2: Start Web
pnpm --filter web dev

# Terminal 3: Start Database (if using Docker)
docker compose up
```

### Verifying Your Setup

```bash
# Check that all checks pass
pnpm lint
pnpm typecheck
pnpm test
```

---

## Project Structure

### Monorepo Layout

```
tutornexus/
├── apps/
│   ├── api/           # Cloudflare Workers backend
│   └── web/          # React frontend
├── services/
│   ├── mcp/          # Go MCP server (subtree)
│   └── adapters/     # TypeScript adapters (subtree)
├── tools/
│   └── cli/          # Rust CLI (subtree)
├── packages/          # Shared TypeScript packages
├── docs/              # Documentation
└── d1/               # Database migrations
```

### Component Ownership

| Directory | Owner | Description |
|-----------|-------|-------------|
| `apps/api/` | Backend team | API implementation |
| `apps/web/` | Frontend team | React frontend |
| `services/mcp/` | MCP team | MCP server |
| `services/adapters/` | Adapter team | Institution adapters |
| `tools/cli/` | CLI team | Rust CLI |
| `packages/*` | All | Shared utilities |

---

## Coding Standards

### Git Conventions

#### Branch Naming

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feature/<issue>-<description>` | `feature/123-add-session-history` |
| Bugfix | `bugfix/<issue>-<description>` | `bugfix/456-fix-quota-overflow` |
| Docs | `docs/<description>` | `docs/update-api-docs` |
| Infra | `infra/<description>` | `infra/add-d1-migration` |

#### Commit Messages

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Restructuring
- `perf`: Performance
- `test`: Testing
- `chore`: Maintenance

**Examples:**
```
feat(api): add tn_transfer_resolve tool

Implement transfer resolution with multi-course support.
Includes credit conversion and evidence linking.

Closes #123
```

```
fix(mcp): handle missing course references

Return empty array instead of error when course not found.
```

### Changelog Generation

This project uses [git-cliff](https://git-cliff.org/) to generate changelogs from conventional commits.

**Install git-cliff:**

```bash
# Via cargo (requires Rust)
cargo install git-cliff

# Via Homebrew
brew install git-cliff

# Download binary
curl -L https://github.com/orhun/git-cliff/releases/latest/download/git-cliff-linux.tar.gz | tar xz
sudo mv git-cliff /usr/local/bin/
```

**Generate changelog:**

```bash
# Preview changelog
git-cliff --config cliff.toml

# Generate and write to file
git-cliff --config cliff.toml --output CHANGELOG.md
```

**Git-cliff configuration:** See `cliff.toml` in repository root.

### Code Style

#### TypeScript

```typescript
// Use strict TypeScript
// Use Zod for validation
// Use ESLint + Prettier

interface Session {
  id: string;
  userId: string | null;
  status: 'active' | 'paused' | 'ended';
  createdAt: Date;
}

// Prefer functional components in React
function Button({ onClick, children }: ButtonProps) {
  return <button onClick={onClick}>{children}</button>;
}
```

#### Go

```go
// Use gofmt for formatting
// Use golangci-lint for linting
// Use context for cancellation

func (s *Server) CreateSession(ctx context.Context, req CreateSessionRequest) (*Session, error) {
    if req.UserID == "" {
        return nil, fmt.Errorf("user ID required: %w", ErrInvalidRequest)
    }
    // ...
}
```

#### Rust

```rust
// Use cargo fmt for formatting
// Use cargo clippy for linting
// Use anyhow for error handling

fn parse_course_code(input: &str) -> Result<(String, String)> {
    let parts: Vec<&str> = input.split(':').collect();
    if parts.len() != 2 {
        anyhow::bail!("invalid course format: {}", input);
    }
    Ok((parts[0].to_string(), parts[1].to_string()))
}
```

---

## Testing Requirements

### Test Coverage

| Type | Minimum | Target |
|------|---------|--------|
| Unit Tests | 80% | 90% |
| Integration Tests | 60% | 80% |
| API Endpoints | 100% | 100% |

### Running Tests

```bash
# Run all tests
pnpm test

# Run unit tests
pnpm test:unit

# Run integration tests
pnpm test:integration

# Run E2E tests
pnpm test:e2e

# Generate coverage report
pnpm test:coverage
```

### Writing Tests

```typescript
// Unit test example
describe('parseCourseRef', () => {
  it('should parse valid course reference', () => {
    const result = parseCourseRef('sfu:CMPT 120');
    expect(result).toEqual({
      institution: 'sfu',
      code: 'CMPT 120',
    });
  });
});
```

---

## Submitting Changes

### Pull Request Process

1. **Create PR from your fork**
   ```bash
   git push origin feature/your-feature
   ```
   Then open a PR at https://github.com/eschmechel/tutornexus/compare

2. **Fill out PR template**

```markdown
## Description
[Brief description of changes]

## Type of Change
- [ ] Bug fix (non-breaking change)
- [ ] New feature (non-breaking change)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] E2E tests added/updated

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or my feature works
- [ ] New and existing unit tests pass locally with my changes
```

3. **Address feedback**
   - Respond to reviewer comments
   - Make requested changes
   - Push additional commits

4. **Squash and merge**
   - Squash commits into logical units
   - Keep meaningful commit messages

### PR Requirements

| Requirement | Details |
|------------|---------|
| Tests | All tests must pass |
| Lint | No lint errors |
| Coverage | Must not decrease |
| Reviews | 1 approval (core), 2 (external) |
| CI | All checks must pass |

---

## Code Review Process

### For Reviewers

1. **Check functionality**
   - Does it do what the PR description says?
   - Are there edge cases not handled?

2. **Check code quality**
   - Is it readable and well-structured?
   - Are there obvious improvements?

3. **Check tests**
   - Are there adequate tests?
   - Do tests actually verify the behavior?

4. **Check documentation**
   - Are there comments for complex logic?
   - Is documentation updated?

### For Authors

1. **Be responsive**
   - Answer questions promptly
   - Explain your reasoning

2. **Be receptive**
   - Accept constructive feedback
   - Ask for clarification if needed

3. **Be patient**
   - Reviewers have other responsibilities
   - Complex PRs take longer to review

---

## Community

### Communication Channels

| Channel | Purpose |
|---------|---------|
| [GitHub Discussions](https://github.com/eschmechel/tutornexus/discussions) | Questions and ideas |
| [GitHub Issues](https://github.com/eschmechel/tutornexus/issues) | Bug reports and feature requests |
| [Discord](https://discord.gg/tutornexus) | Real-time chat |

### Contributing Areas

| Area | Description | Good for |
|------|-------------|---------|
| Frontend | React components, UI | Beginners |
| Backend | API, database | Some experience |
| MCP | Go server | Go experience |
| CLI | Rust application | Rust experience |
| Adapters | Scrapers, integrations | Web scraping |
| Docs | Documentation | Non-coding contributors |

### First-Time Contributors

Looking for a good first issue? Check:
- [Good First Issues](https://github.com/eschmechel/tutornexus/labels/good%20first%20issue)
- [Help Wanted](https://github.com/eschmechel/tutornexus/labels/help%20wanted)

---

## Recognition

Contributors are recognized in:
- [CONTRIBUTORS.md](CONTRIBUTORS.md)
- Release notes
- Documentation credits

---

## Thank You!

Your contributions make Tutor Nexus possible. We appreciate your time and effort!

---

## Security Guidelines

All contributors must follow these security practices:

### Never Commit Secrets

```bash
# ✅ Correct
cp .env.example .env
# Edit .env with your local values (gitignored)

# ❌ Never
echo "API_KEY=secret123" >> .env.local
git add .env.local
```

**What to never commit:**
- API keys and tokens
- Database credentials
- Private keys and certificates
- Personal access tokens
- Environment files (`.env*` except `.env.example`)

### Security Requirements for PRs

| Requirement | Description |
|-------------|-------------|
| **Secrets Scanning** | CI will fail if secrets are detected |
| **Dependency Audit** | Address high/critical vulnerabilities |
| **CodeQL Analysis** | Fix security warnings |
| **Input Validation** | Use Zod schemas for all input |
| **Parameterized Queries** | Never concatenate SQL |

### Security Review for Sensitive Changes

Changes to these areas require additional review:

- Authentication/authorization code
- Encryption implementation
- API endpoint changes
- Database schema changes
- Third-party integrations
- Secrets management

### Reporting Vulnerabilities

If you discover a security vulnerability:

1. **Do NOT** create a public issue
2. **Do NOT** exploit the vulnerability
3. **Email**: security@tutor-nexus.com
4. **Or use**: GitHub Private Vulnerability Reporting

See [SECURITY.md](SECURITY.md) for full disclosure policy.

### Security Best Practices

- Validate all input with Zod schemas
- Use prepared statements for database queries
- Escape output when rendering user data
- Follow the principle of least privilege
- Keep dependencies updated
- Use HTTPS for all external requests
- Log security events for audit trails

---

## Quick Reference

```bash
# Setup
git clone https://github.com/YOUR-USERNAME/tutornexus
cd tutornexus
git remote add upstream https://github.com/eschmechel/tutornexus.git
pnpm install
cp .env.example .env
wrangler login

# Development
git checkout -b feature/your-feature
pnpm lint && pnpm typecheck && pnpm test
git add . && git commit -m "feat(scope): description"
git push origin feature/your-feature

# Create PR
#   Go to https://github.com/YOUR-USERNAME/tutornexus
#   Click "Compare & pull request"
```

**Questions?** Reach out in [Discussions](https://github.com/eschmechel/tutornexus/discussions)!
