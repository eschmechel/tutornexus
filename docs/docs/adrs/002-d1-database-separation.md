---
title: ADR-002 - Separate D1 Databases per Domain
description: Separate D1 databases for sessions, courses, and adapters.
sidebar_position: 3
---

# ADR-002: Separate D1 Databases per Domain

- Status: Accepted
- Date: 2026-02-04

## Context

We want clear data ownership boundaries between user/session concerns and course/catalog concerns, and we expect adapters to ingest data with distinct lifecycles. In the previous hackathon implementation, we had a single D1 database and had issues with seeding and migration.

## Decision

Use separate Cloudflare D1 databases with `tn-*` naming.

- `tn-sessions`: auth, users, sessions, quota usage, BYOK key material (encrypted)
- `tn-courses`: normalized course catalog
- `tn-adapter-*`: adapter-specific ingestion/caches, one per institution/adapter (e.g., `tn-adapter-sfu`)

## Consequences

- Reduced blast radius for migrations and ingestion bugs.
- Clearer access patterns and ownership.
- More bindings to configure in Wrangler.

## Alternatives considered

- Single D1 database: fewer bindings but more coupling and migration risk.
