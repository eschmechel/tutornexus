---
title: ADR-009 - Authentication via Lucia
description: Lucia Auth with Workers + D1 adapter.
sidebar_position: 10
---

# ADR-009: Auth via Lucia

- Status: Accepted
- Date: 2026-02-04

## Context

We need authentication compatible with Cloudflare Workers and D1.

## Decision

- Use Lucia Auth with a Workers + D1 adapter.

## Consequences

- Session management and user identity are standardized.
- Auth schema lives primarily in `tn-sessions`.

## Alternatives considered

- Roll our own auth: too risky.
