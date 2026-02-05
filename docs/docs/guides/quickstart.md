---
title: Quick Start Guide
description: Get started with Tutor Nexus development in minutes.
sidebar_position: 1
---

This guide will help you set up your development environment and run Tutor Nexus locally.

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Node.js | >= 20.0.0 | Runtime for web apps |
| pnpm | >= 9.0.0 | Package manager |
| Git | Latest | Version control |
| Cloudflare Wrangler | Latest | Workers deployment |
| Go | 1.25+ | MCP server development |
| Rust | Latest | CLI development |

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/eschmechel/tutornexus.git
cd tutornexus
```

### 2. Install Dependencies

```bash
# Install pnpm if not already installed
npm install -g pnpm

# Install all workspace dependencies
pnpm install
```

### 3. Configure Environment

Copy the example environment file and fill in your values:

```bash
cp .env.example .env
```

Required variables:

```env
# Database (D1)
DATABASE_URL=.wrangler/state/d1/.sqlite

# Auth
AUTH_SECRET=your-lucia-auth-secret
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# API Keys (for BYOK feature)
OPENAI_API_KEY=your-openai-key
ELEVENLABS_API_KEY=your-elevenlabs-key

# Cloudflare
CLOUDFLARE_API_TOKEN=your-cloudflare-token
CLOUDFLARE_ACCOUNT_ID=your-account-id
```

### 4. Set Up Database

```bash
# Create local D1 databases
pnpm db:setup

# Run migrations
pnpm db:migrate
```

### 5. Start Development Servers

#### All Services

```bash
pnpm dev
```

This starts:
- API server at `http://localhost:8787`
- Web app at `http://localhost:5173`
- Docs at `http://localhost:3000`

#### Individual Services

```bash
# API only
pnpm dev:api

# Web only
pnpm dev:web

# Docs only
pnpm dev:docs
```

## Verifying the Setup

### Health Check

```bash
curl http://localhost:8787/health
```

Expected response:
```json
{
  "status": "healthy",
  "version": "0.1.0",
  "timestamp": "2026-02-04T00:00:00Z"
}
```

### API Documentation

Visit `http://localhost:8787/docs` for the Swagger UI.

## Common Issues

### Port Already in Use

```bash
# Find and kill the process
lsof -ti:8787 | xargs kill -9

# Or use a different port
pnpm dev:api -- --local-port 8788
```

### Database Errors

```bash
# Reset the database
rm -rf .wrangler/state/d1
pnpm db:setup
pnpm db:migrate
```

### Node Version Mismatch

```bash
# Using nvm
nvm use 20

# Using volta
volta install node@20
```

## Next Steps

Once your environment is set up:

1. **Read the [Development Guide](/docs/guides/development)** - Learn coding conventions
2. **Explore the [API](/docs/reference/api)** - Understand the endpoints
3. **Review [Architecture](/docs/adrs)** - Understand design decisions
4. **Check the [Testing Guide](/docs/guides/testing)** - Learn how to test

## Support

- **GitHub Issues**: Report bugs and request features
- **Discord**: Join our community server
- **Documentation**: See the [full docs](/)
