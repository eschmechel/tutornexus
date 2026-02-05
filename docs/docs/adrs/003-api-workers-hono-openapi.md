---
title: ADR-003 - Cloudflare Workers API with Hono + OpenAPI
description: Hono routing with @hono/zod-openapi for OpenAPI generation.
sidebar_position: 4
---

# ADR-003: Cloudflare Workers API with Hono + OpenAPI

- Status: Accepted
- Date: 2026-02-04

## Context

We want a Workers-native API stack with excellent TypeScript ergonomics, low overhead, and strong documentation.

## Decision

- Build the API as TypeScript Cloudflare Workers.
- Use Hono for routing.
- Use `@hono/zod-openapi` to generate OpenAPI from route schemas.

## Consequences

- OpenAPI becomes enforceable and generated from source.
- Strong typing at request boundaries.

## Alternatives considered

- Express-style frameworks: not Workers-native.
- Manual OpenAPI: drifts quickly.
