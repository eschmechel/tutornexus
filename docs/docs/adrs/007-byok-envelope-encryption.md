---
title: ADR-007 - BYOK Storage using Envelope Encryption
description: Envelope encryption with KEK and DEK for user credentials.
sidebar_position: 8
---

# ADR-007: BYOK Storage using Envelope Encryption

- Status: Accepted
- Date: 2026-02-04

## Context

Users can supply their own LLM credentials (BYOK). We must:

- support OpenAI API keys and Ollama endpoints/keys from day one
- encrypt secrets at rest
- enable key rotation
- avoid storing plaintext secrets in D1

## Decision

Use envelope encryption for BYOK credentials:

- KEK (key-encryption-key) stored as a Cloudflare Secret.
- Per-user (or per-credential) DEK used to encrypt the actual credential payload.
- Store encrypted payload + metadata in D1 (`tn-sessions`).

## Consequences

- Compromise of D1 alone does not reveal plaintext keys.
- We need a clear rotation story (rotate KEK and/or rewrap DEKs).
- We need careful logging hygiene to avoid leaking secrets.

## Alternatives considered

- Store keys plaintext in D1: unacceptable.
- Hash keys only: not usable for outbound API calls.
