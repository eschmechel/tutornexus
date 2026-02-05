---
title: Deployment Guide
description: Deploy Tutor Nexus to Cloudflare Workers and Pages.
sidebar_position: 3
---

## Overview

Tutor Nexus deploys to Cloudflare's edge network:

- **API**: Cloudflare Workers
- **Web App**: Cloudflare Pages
- **Docs**: Cloudflare Pages (Astro Starlight)
- **Database**: D1 (SQLite at edge)

## Environments

| Environment | URL | Purpose |
|-------------|-----|---------|
| Production | api.tutor-nexus.com | Live users |
| Staging | staging.tutor-nexus.com | Testing releases |
| Preview | PR-specific | Review PR changes |

## Prerequisites

1. Cloudflare account with Workers and Pages enabled
2. Wrangler CLI installed and authenticated
3. All tests passing locally

## Deployment Steps

### 1. Prepare for Release

```bash
# Update version in package.json
# Bump version according to semver

# Run full test suite
pnpm test
pnpm lint
pnpm typecheck

# Build all packages
pnpm build
```

### 2. Deploy API

```bash
# Deploy to production
pnpm deploy:api

# Or with preview
pnpm deploy:api --env staging
```

### 3. Deploy Web

```bash
# Deploy to production
pnpm deploy:web

# Preview deployment
pnpm deploy:web --env staging
```

### 4. Deploy Docs

```bash
# Build docs
pnpm build:docs

# Deploy to Cloudflare Pages
pnpm deploy:docs
```

## Environment Configuration

### Production Secrets

```bash
# Set production secrets
wrangler secret put AUTH_SECRET --name tutor-nexus-api
wrangler secret put DATABASE_URL --name tutor-nexus-api
wrangler secret put OPENAI_API_KEY --name tutor-nexus-api
```

### D1 Database Setup

```bash
# Create production databases
wrangler d1 create tn-sessions --env production
wrangler d1 create tn-courses --env production
wrangler d1 create tn-transfers --env production

# Apply migrations
wrangler d1 migrations apply tn-sessions --env production
wrangler d1 migrations apply tn-courses --env production
wrangler d1 migrations apply tn-transfers --env production
```

## Rollback Procedure

### API Rollback

```bash
# List recent deployments
wrangler deployments list --name tutor-nexus-api

# Rollback to previous version
wrangler deployments roll-back tutor-nexus-api <deployment-id>
```

### Web Rollback

Cloudflare Pages maintains deployment history:

1. Go to Pages dashboard
2. Select the production deployment
3. Click "Restore previous deployment"

## Monitoring

### Logs

```bash
# Real-time logs
wrangler tail --project-name=tutor-nexus-api

# Filter by error
wrangler tail --project-name=tutor-nexus-api --status error
```

### Metrics

View metrics in Cloudflare Dashboard:
- Requests per second
- Error rate
- Latency percentiles
- CPU/Bandwidth usage

### Alerts

Configure alerts for:
- Error rate > 1%
- Latency p99 > 500ms
- 5xx errors > threshold

## CI/CD Pipeline

The repository uses GitHub Actions for automated deployments:

```yaml
# .github/workflows/deploy.yml

on:
  push:
    branches: [main]
  pull_request:
    types: [opened, synchronize]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: pnpm install
      - run: pnpm test
      - run: pnpm build
      - run: pnpm deploy:api
      - run: pnpm deploy:web
      - run: pnpm deploy:docs
```

## Troubleshooting

### Deployment Fails

```bash
# Check deployment logs
wrangler deployments list --name tutor-nexus-api

# Validate wrangler.toml
wrangler validate

# Check syntax errors
pnpm typecheck
```

### Database Connection Issues

```bash
# Verify D1 database exists
wrangler d1 list

# Check binding configuration
cat wrangler.toml | grep -A 10 "\[\[d1_databases\]\]"
```

### Domain Not Resolving

```bash
# Check DNS configuration
dig api.tutor-nexus.com

# Verify custom domain in Cloudflare
wrangler deployments list --name tutor-nexus-api
```
