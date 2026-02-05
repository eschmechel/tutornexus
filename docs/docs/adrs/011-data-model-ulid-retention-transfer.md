---
title: ADR-011 - Data Model Conventions
description: ULID identifiers, retention policies, transfer model.
sidebar_position: 12
---

# ADR-011: Data Model Conventions (ULID, Retention, Transfers)

- Status: Accepted
- Date: 2026-02-04

## Context

We need consistent identifiers across TypeScript, Go, and Rust, and clear retention policies for user data. We also need a transfer model that supports real-world equivalencies.

## Decision

- Use ULID as the default identifier type across services.
- Session retention:
  - Keep full session transcripts for 90 days, then anonymize.
  - Delete anonymous sessions older than 1 year.
  - "7-day TTL" applies only to cached artifacts (e.g., embeddings/index/summaries), not session retention.
- Transfer model must support:
  - multi-course equivalencies (sets of source courses mapping to a target)
  - generic/elective credit targets (e.g., `CPSC 1XX (3 credits)`)
  - credit conversion (source and target credits may differ)

## Consequences

- All services must adopt ULID libraries compatible with their language.
- Retention/anonymization jobs must be implemented and tested.
- Transfer schema and resolution APIs must treat multi-course sets and generic targets as first-class.

## Alternatives considered

- UUIDv4 everywhere: workable, but ULID provides better sorting semantics.
- Model transfers as only 1:1 course mappings: insufficient.
