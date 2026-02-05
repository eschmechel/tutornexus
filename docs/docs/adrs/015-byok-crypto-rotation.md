---
title: ADR-015 - BYOK Cryptography and Key Rotation
description: Envelope encryption, KEK versioning, lazy re-wrapping.
sidebar_position: 16
---

# ADR-015: BYOK Cryptography and Key Rotation

- Status: Accepted
- Date: 2026-02-04

## Context

BYOK credentials (OpenAI API keys and Ollama endpoints/keys) must be encrypted at rest [ADR-007](./007-byok-envelope-encryption.md). We also need operationally safe key rotation.

Constraints:

- Store encrypted payload + metadata in D1 (`tn-sessions`).
- KEK is stored as a Cloudflare Secret.
- Never log secrets; never return plaintext keys to clients.
- CLI daemon must authenticate via OAuth device flow to access user's BYOK credentials.

## Decision

### Envelope encryption model

- Generate a per-credential DEK (random bytes).
- Encrypt the credential payload with the DEK.
- Wrap (encrypt) the DEK with the KEK.
- Store:
  - encrypted payload
  - wrapped DEK
  - algorithm metadata
  - KEK version id

### KEK versioning and rotation

- KEKs are versioned (e.g., `BYOK_KEK_V1`, `BYOK_KEK_V2`).
- Each stored credential records `kek_version`.
- Rotation strategy:
  - New writes use the latest KEK.
  - Existing credentials are re-wrapped lazily on successful use and/or via a background job.

### Credential payload shape

- Store payload as a small JSON object, then encrypt.
- Payload contains provider-specific fields, e.g.:
  - OpenAI: `{ "apiKey": "..." }`
  - Ollama: `{ "baseUrl": "http://...", "apiKey": "..." }`

### CLI authentication for BYOK

- CLI daemon authenticates via OAuth device flow [ADR-013](013-live-session-state-durable-objects.md).
- Authenticated CLI can access user's BYOK credentials.
- CLI never receives plaintext keys; it receives encrypted blobs.
- CLI must call API to use credentials (API decrypts on-the-fly).

## Consequences

- Crypto implementation must be correct and testable in Workers.
- We need migration utilities for re-wrapping DEKs.
- Access control must ensure only the owning user can use the credential.
- CLI must proxy all BYOK usage through API (cannot decrypt locally).

## Alternatives considered

- Plaintext storage in D1: unacceptable.
- One global DEK: weakens compartmentalization.

## Implementation notes

- Recommended algorithms: AES-256-GCM for payload, RSA-OAEP for DEK wrapping.
- Store a non-reversible fingerprint (hash) for duplicate detection.
- BYOK keys are per-user (not per-session) for simplicity.
