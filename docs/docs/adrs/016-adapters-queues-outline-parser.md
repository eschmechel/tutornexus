---
title: ADR-016 - Adapter Pipeline Architecture
description: TS Workers + Cloudflare Queues + Go parser, R2 storage.
sidebar_position: 17
---

# ADR-016: Adapter Pipeline (Workers + Queues + Go Outline Parser)

- Status: Accepted
- Date: 2026-02-04

## Context

We ingest course catalogs, prerequisites, and outlines from multiple institutions. Some sources are HTML; others include PDFs and unstructured documents.

Constraints:

- Cloudflare Workers request handlers have tight CPU limits.
- Cloudflare Queue consumers can perform heavier processing than HTTP handlers.
- We want a hybrid approach: Workers for orchestration + ingestion; Go service for complex outline parsing.

## Decision

### Adapter architecture

- **Adapter Workers (TypeScript)**: Handle orchestration, HTTP fetching, lightweight parsing, queue production
- **Go Outline Parser Service**: Handles heavy PDF/unstructured document parsing, called via Cloudflare Queues

### Folder structure

```
tutornexus/
├── apps/
│   ├── web/          (React frontend)
│   └── api/          (Workers backend)
├── services/
│   ├── mcp/          (Go MCP server - subtree)
│   └── adapters/     (TypeScript adapter Workers)
├── tools/
│   └── cli/          (Rust CLI - subtree)
├── docs/
└── storage/          (R2 for raw artifacts)
```

### Worker-based ingestion

- Each institution adapter runs as a separate Cloudflare Worker module.
- Scheduled runs are triggered via Cron.
- Adapters enqueue work items to Cloudflare Queues.
- Queue consumers fetch source documents and parse/normalize results.

### Outline parsing (Go service)

Queue consumers invoke a dedicated Go service for:
- PDFs
- Unstructured outlines
- Expensive parsing tasks

**Deployment:**
- Render free tier for dev/staging
- Fly.io for production

### Storage

- **R2**: Store large raw artifacts (HTML, PDFs, images)
- **Adapter-specific D1** (`tn-adapter-*`):
  - Raw fetch metadata (URLs, ETags, timestamps)
  - Parse outputs and adapter-local indices
  - Cached normalized data
- **Main D1** (`tn-courses`): Normalized course catalog

### Reliability and idempotency

- Queue jobs are idempotent and keyed by a stable content hash.
- Retries must not create duplicate normalized records.
- Failed jobs:
  - Retry N times with exponential backoff
  - Then move to dead-letter queue (DLQ) for manual review

### Initial adapters (Phase 1)

| Adapter | Institution | Notes |
|---------|-------------|-------|
| `tn-adapter-sfu` | Simon Fraser University | Priority |
| `tn-adapter-langara` | Langara College | Priority |
| `tn-adapter-ubc` | University of BC | Priority |
| `tn-adapter-douglas` | Douglas College | Priority |
| `tn-adapter-tru` | Thompson Rivers University | Priority |
| `tn-adapter-bctransfer` | BC Transfer Guide | Transfer data |

Additional adapters may be added in future phases.

### Canonical normalized schema

Unified schema for course data with optional fields:

```typescript
interface NormalizedCourse {
  courseRef: string;           // "institution:code" (e.g., "sfu:CMPT 120")
  institution: string;          // "sfu", "langara", etc.
  code: string;                // "CMPT 120"
  title: string;
  description: string;
  credits: number;             // Original credits
  equivalentCredits?: number;   // Credits when transferred
  prerequisites: string[];      // Course references
  corequisites: string[];
  antirequisites: string[];
  equivalentTo?: string[];      // Equivalent courses
  conditions?: string;         // "Grade of B or better"
  validFrom?: string;          // Term code or date
  validUntil?: string;
  updatedAt: string;           // RFC3339
  sourceUrls: string[];        // For evidence
}

interface NormalizedOutline {
  courseRef: string;
  learningOutcomes: string[];
  gradingScheme: {
    component: string;
    weight: number;
  }[];
  topics: string[];
  requiredTexts?: string[];
  recommendedTexts?: string[];
  policies?: string;
}
```

## Consequences

- More moving parts (Workers + Queues + Go service).
- Better reliability and performance for heavy parsing.
- Clear separation between ingestion (adapter DBs) and product catalog (`tn-courses`).
- Raw artifacts in R2 reduce D1 storage costs.

## Alternatives considered

- All-Go scrapers: higher ops cost, less Workers-native.
- All-Workers parsing: limited by runtime for heavy PDF/unstructured parsing.

## Implementation notes

- Adapter schema may evolve; optional fields allow backward compatibility.
- Dead-letter queue requires monitoring and manual intervention process.
- BC Transfer Guide adapter requires attribution in UI.
