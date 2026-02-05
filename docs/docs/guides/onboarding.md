---
title: Onboarding Guide
description: New developer onboarding guide for Tutor Nexus.
sidebar_position: 6
---

Welcome to the Tutor Nexus team! This guide will help you get started.

## Before You Begin

### Required Accounts

| Service | Purpose | Sign Up |
|---------|---------|---------|
| GitHub | Code repository | github.com/signup |
| Cloudflare | Infrastructure | cloudflare.com |


### Required Software

- Node.js 20+
- pnpm 9+
- Git
- VS Code (recommended)
- Docker (optional, for Go development)

## Day 1: Setup

### 1. Clone and Install

```bash
# Clone the repository
git clone https://github.com/tutor-nexus/tutornexus.git
cd tutornexus

# Install pnpm if needed
npm install -g pnpm

# Install all dependencies
pnpm install
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit with your values
nano .env
```

Required variables:
- `AUTH_SECRET` - Generate with `openssl rand -hex 32`
- `CLOUDFLARE_API_TOKEN` - Create in Cloudflare dashboard
- `GOOGLE_CLIENT_ID/SECRET` - For OAuth (optional initially)

### 3. Set Up Cloudflare

```bash
# Login to Wrangler
npx wrangler login

# Verify access
npx wrangler whoami
```

### 4. Verify Setup

```bash
# Run the development server
pnpm dev

# Visit http://localhost:8787/health
# Should return {"status":"healthy"}
```

## Understanding the Architecture

### Core Concepts

1. **Workers** - Edge functions handling API requests
2. **D1** - SQLite databases at the edge
3. **Durable Objects** - Real-time state management
4. **Queues** - Async job processing
5. **R2** - Object storage for artifacts

### Data Flow

```
User → Cloudflare CDN → Workers API → D1 Database
                                      ↓
                              Vectorize (RAG)
                                      ↓
                              MCP Server (Go)
```

### Key Files

| Path | Purpose |
|------|---------|
| `apps/api/src/index.ts` | API entry point |
| `apps/api/src/routes/` | API route handlers |
| `d1/migrations/` | Database schema |
| `docs/adr/` | Architecture decisions |

## Your First Task

### Good First Issues

Look for issues labeled:
- `good first issue`
- `help wanted`
- `documentation`

### Making Changes

1. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   ```bash
   # Edit files as needed
   code .
   ```

3. **Run tests**
   ```bash
   pnpm test
   pnpm lint
   ```

4. **Commit**
   ```bash
   git add .
   git commit -m "feat(api): add your feature"
   ```

5. **Push and PR**
   ```bash
   git push origin feature/your-feature-name
   # Open PR from GitHub UI
   ```

## Development Workflow

### Daily Routine

```bash
# Start the day
git checkout main
git pull

# Create or switch to your branch
git checkout feature/your-task

# Make changes
# ...

# Run tests
pnpm test

# Commit
git add -A
git commit -m "feat(scope): description"

# Push
git push origin feature/your-task
```

### Code Review

1. Keep PRs small (< 400 lines ideally)
2. Write clear descriptions
3. Self-review before requesting
4. Address feedback promptly

### Communication

- **Discord**: Team channels for discussion
- **GitHub Issues**: Feature requests and bugs
- **PR Comments**: Technical discussions

## Learning Resources

### Internal

- [Architecture Decisions](/docs/adrs)
- [API Documentation](/docs/reference/api)
- [Development Guide](/docs/guides/development)

### External
- [Hono.js Docs](https://hono.dev/)
- [Cloudflare Workers](https://developers.cloudflare.com/workers/)
- [Lucia Auth](https://lucia-auth.com/)
- [D1 Database](https://developers.cloudflare.com/d1/)

## FAQ

### Q: Where do I find the database schema?

See `d1/migrations/` for all database schemas.

### Q: How do I add a new API endpoint?

1. Define Zod schema in `apps/api/src/schemas/`
2. Create route in `apps/api/src/routes/`
3. Register in `apps/api/src/index.ts`
4. Add tests

### Q: How do I run just the API?

```bash
pnpm dev:api
```

### Q: How do I test changes to the database?

```bash
# Apply migrations locally
pnpm db:migrate

# Open database console
pnpm db:console
```

### Q: Where are environment variables used?

- API routes: `c.get('env').VARIABLE_NAME`
- Wrangler: Defined in `wrangler.toml` or secrets

## Getting Help

1. **Check docs** - Start with documentation
2. **Search issues** - Similar problems may exist
3. **Ask in Discord** - Team members can help
4. **Create issue** - Document the problem

## Next Steps

After onboarding:

1. [ ] Set up development environment
2. [ ] Review key ADRs
3. [ ] Make first contribution
4. [ ] Join code review rotation
5. [ ] Participate in doc sprints

Welcome aboard! 🎉
