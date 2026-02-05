---
title: ADR-008 - RAG Vector Store
description: Cloudflare Vectorize for cloud RAG, optional FAISS for local.
sidebar_position: 9
---

# ADR-008: RAG Vector Store (Cloud) + Optional Local FAISS

- Status: Accepted
- Date: 2026-02-04

## Context

We want retrieval augmentation for course data, notes, and tutoring sessions.

## Decision

- Use Cloudflare Vectorize for the hosted/vector RAG path.
- CLI may optionally support local/offline RAG via FAISS.

## Consequences

- Hosted flows rely on Cloudflare primitives.
- Offline mode requires separate indexing and storage strategies.

## Alternatives considered

- Single approach only (cloud or local): reduces flexibility.
