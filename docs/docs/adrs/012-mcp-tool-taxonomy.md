---
title: ADR-012 - MCP Tool Taxonomy and Naming
description: 28 tools across 4 domains with Zod schemas and pagination.
sidebar_position: 13
---

# ADR-012: MCP Tool Taxonomy and Naming

- Status: Accepted
- Date: 2026-02-04

## Context

We need a stable, discoverable set of MCP tools that covers tutoring, course catalog lookup, and transfer resolution. Tools must remain backwards-compatible as we add new capabilities, and documentation must be auto-generatable.

Transfers must represent real-world equivalencies, including:

- multi-course equivalencies (paired/multi-course sets)
- generic/elective credit targets (e.g., `CPSC 1XX (3 credits)`)
- credit conversion (source and target credits may differ)

## Decision

### Tool naming

- Tool names follow `tn_<domain>_<verb>` in snake_case.
- `tn_` is reserved for Tutor Nexus tools.
- New tools and fields are added in a backwards-compatible way (additive; avoid breaking renames).

Examples:

- `tn_session_start`
- `tn_session_ask`
- `tn_session_end`
- `tn_course_search`
- `tn_course_get`
- `tn_transfer_resolve`

### Domain conventions

Initial domains (expandable):

- `session`: tutoring sessions and messages
- `course`: catalog search and retrieval
- `transfer`: transfer resolution and equivalency lookup
- `user`: BYOK credentials, preferences, quotas (renamed from `account`)

### Identifiers and time

- IDs are ULIDs.
- Timestamps are RFC3339 strings.

### Session-based tutoring

Tutoring tools are session-id based:

- `tn_session_start` returns `session_id` (ULID)
- `tn_session_ask` requires `session_id`
- `tn_session_end` requires `session_id`

This enables reconnect/resume, consistent retention rules, and durable provenance.

### Session export and sync (CLI ↔ Webapp)

For bidirectional sync between CLI daemon and webapp:

| Tool | Purpose |
|------|---------|
| `tn_session_export` | Generate a portable session snapshot for webapp import |
| `tn_session_sync_status` | Check if session has pending sync from other device |
| `tn_session_cancel_pending` | Cancel pending/draft messages before they are sent |

Sync behavior:
- CLI daemon syncs with every edit (5s polling interval)
- Webapp polls every 60 seconds OR manual refresh
- Bidirectional sync is supported
- Pending/draft messages can be cancelled

### Course references

When a tool requires a course reference, it accepts a canonical string form:

- `institution:course_code`

Examples:

- `sfu:CMPT 120`
- `langara:CMPT 1160`

Normalization rules are implementation-defined but must be consistent within a release (e.g., trimming, collapsing whitespace, case-insensitive institution + subject).

### Complete tool list

#### Session domain (session)

| Tool | Purpose | Pagination |
|------|---------|------------|
| `tn_session_start` | Create a new tutoring session | N/A |
| `tn_session_ask` | Send a message within a session | N/A |
| `tn_session_end` | Close a session gracefully | N/A |
| `tn_session_history` | Retrieve session transcript (paginated) | Cursor-based |
| `tn_session_resume` | Reconnect to an existing session | N/A |
| `tn_session_export` | Generate portable snapshot for webapp sync | N/A |
| `tn_session_sync_status` | Check pending sync status | N/A |
| `tn_session_cancel_pending` | Cancel pending/draft messages | N/A |

#### Course domain (course)

| Tool | Purpose | Pagination |
|------|---------|------------|
| `tn_course_search` | Search courses by keyword/institution | Cursor-based |
| `tn_course_get` | Get detailed course info by reference | N/A |
| `tn_course_prereqs` | Get prerequisites for a course | N/A |
| `tn_course_requisites` | Get requisites (corequisites, antirequisites) | N/A |
| `tn_course_outline` | Get course outline/syllabus (if available) | N/A |
| `tn_course_instructor` | Get instructor info for a course | N/A |
| `tn_course_schedule` | Get scheduled offerings (term, section, times) | Cursor-based |
| `tn_course_similar` | Find similar courses at same institution | Cursor-based |
| `tn_course_institutions` | List available institutions | Cursor-based |
| `tn_course_equivalent_elsewhere` | Find equivalent courses at other schools | Cursor-based |
| `tn_course_materials` | Get available materials (past exams, homework) | Cursor-based |
| `tn_course_grades` | Get grade distribution, averages | N/A |
| `tn_course_section_get` | Get specific section details (times, instructor) | N/A |
| `tn_course_section_list` | List all sections for a term | Cursor-based |

#### Transfer domain (transfer)

| Tool | Purpose | Pagination |
|------|---------|------------|
| `tn_transfer_resolve` | Resolve source courses to target equivalencies | N/A |
| `tn_transfer_search` | Search transfer agreements by institution pair | Cursor-based |
| `tn_transfer_details` | Get detailed transfer rule with evidence | N/A |

#### User domain (user)

| Tool | Purpose | Pagination |
|------|---------|------------|
| `tn_user_byok_list` | List user's BYOK credentials | Cursor-based |
| `tn_user_byok_add` | Add a new BYOK credential | N/A |
| `tn_user_byok_delete` | Remove a BYOK credential | N/A |
| `tn_user_preferences_get` | Get user preferences (voice, theme, etc.) | N/A |
| `tn_user_preferences_set` | Update user preferences | N/A |
| `tn_user_quota` | Get current quota usage | N/A |
| `tn_user_subscription` | Get subscription status | N/A |

### Pagination conventions

All list-like tools use cursor-based pagination.

#### Pagination parameters

| Param | Type | Description |
|-------|------|-------------|
| `limit` | integer | Max items per page (default: 20, max: 100) |
| `cursor` | string | Opaque cursor for next page (from previous response) |

#### Pagination response schema

```typescript
interface PaginatedResponse<T> {
  items: T[];
  nextCursor?: string;
  totalCount?: number;
  hasMore: boolean;
}
```

#### Example

```typescript
// Request
tn_course_search({ 
  query: "computer science", 
  limit: 10,
  cursor: "abc123" 
});

// Response
{
  items: [/* 10 course objects */],
  nextCursor: "xyz789",
  totalCount: 342,
  hasMore: true
}
```

### Transfer resolution

`tn_transfer_resolve` takes a set of source courses and resolves equivalencies to a target institution.

Input (conceptual):

- `sourceInstitution` (string)
- `targetInstitution` (string)
- `sourceCourses: string[]` (set semantics; order does not matter)
- `asOfDate` (optional RFC3339 date/time; used for effective-term filtering)

Output returns BOTH by default:

- `exactMatches`: equivalencies satisfied by the provided `sourceCourses`
- `partialMatches`: equivalencies that are close but not yet satisfied

Partial matches are not just fuzzy text matches. They also cover set-based transfer requirements such as:

- "you have 1 of 2 required courses" (missing courses are reported)

Targets support:

- `course` (specific target course)
- `generic` (pattern/generic credit like `CPSC 1XX`)
- `elective` (elective credit buckets)

Every match must be capable of carrying:

- credit conversion: source credits and target credits
- effective range: `effectiveStart`, `effectiveEnd` (optional)
- evidence: one or more links/refs to the source of truth
- confidence: machine-scored and/or provenance-scored (implementation-defined)

### Tool schema definition (Zod)

Tool schemas are defined using Zod for type safety and OpenAPI compatibility.

#### Example: Session tools

```typescript
import { z } from "zod";
import { ulid } from "ulid";

// Common schemas
const UserIdSchema = z.string().ulid();
const SessionIdSchema = z.string().ulid();
const TimestampSchema = z.string().datetime();

// tn_session_start
export const tn_session_start = {
  input: z.object({
    userId: UserIdSchema.optional(), // null for anonymous
    context: z.record(z.unknown()).optional()
  }),
  output: z.object({
    sessionId: SessionIdSchema,
    expiresAt: TimestampSchema
  })
};

// tn_session_ask
export const tn_session_ask = {
  input: z.object({
    sessionId: SessionIdSchema,
    message: z.string().min(1).max(10000)
  }),
  output: z.object({
    response: z.string(),
    eventsEmitted: z.array(z.string())
  })
};

// tn_session_history (paginated)
export const tn_session_history = {
  input: z.object({
    sessionId: SessionIdSchema,
    limit: z.number().min(1).max(100).default(20),
    cursor: z.string().optional()
  }),
  output: z.object({
    items: z.array(z.object({
      eventId: z.string().ulid(),
      seq: z.number(),
      type: z.string(),
      createdAt: TimestampSchema,
      role: z.enum(["user", "assistant"]),
      content: z.string()
    })),
    nextCursor: z.string().optional(),
    hasMore: z.boolean()
  })
};
```

### Error response conventions

All tools return consistent error responses using Zod for validation.

#### Error codes

| Code | Meaning | Client Action |
|------|---------|---------------|
| `BAD_REQUEST` | Invalid input schema | Fix request payload |
| `UNAUTHORIZED` | Missing/invalid auth | Re-authenticate |
| `FORBIDDEN` | Authenticated but not allowed | Check permissions |
| `NOT_FOUND` | Resource doesn't exist | Verify IDs |
| `CONFLICT` | Idempotency violation | Use new client_event_id |
| `UNPROCESSABLE_ENTITY` | Schema valid, business logic fail | See details |
| `RATE_LIMITED` | Quota exceeded | Retry after Retry-After |
| `INTERNAL_ERROR` | Server failure | Retry later |
| `SERVICE_UNAVAILABLE` | Temporary outage | Retry later |

#### Error response schema (Zod)

```typescript
import { z } from "zod";

const ErrorCodeSchema = z.enum([
  "BAD_REQUEST",
  "UNAUTHORIZED",
  "FORBIDDEN",
  "NOT_FOUND",
  "CONFLICT",
  "UNPROCESSABLE_ENTITY",
  "RATE_LIMITED",
  "INTERNAL_ERROR",
  "SERVICE_UNAVAILABLE"
]);

const QuotaLimitSchema = z.object({
  current: z.number(),
  max: z.number(),
  window: z.string()
});

const ErrorDetailSchema = z.object({
  reason: z.string().optional(),
  retryAfter: z.number().optional(),
  limit: QuotaLimitSchema.optional()
});

export const ErrorResponseSchema = z.object({
  code: ErrorCodeSchema,
  message: z.string(),
  details: ErrorDetailSchema.optional(),
  requestId: z.string()
});

export type ErrorResponse = z.infer<typeof ErrorResponseSchema>;
```

#### Example error response

```json
{
  "code": "RATE_LIMITED",
  "message": "Daily prompt limit exceeded",
  "details": {
    "reason": "User has used 100/100 prompts today",
    "retryAfter": 43200,
    "limit": { "current": 100, "max": 100, "window": "day" }
  },
  "requestId": "01JXYZ123ABC"
}
```

### Schema and documentation

- Tool schema is the source of truth.
- Schemas are defined using Zod for type safety.
- Zod schemas are converted to OpenAPI using `@hono/zod-openapi`.
- The schema must be versioned and used to generate MCP tool documentation.

## Consequences

- Callers can rely on consistent naming across domains.
- Transfer tools can express paired/multi-course equivalencies and generic credit targets without lossy workarounds.
- We must maintain a central, versioned tool schema and keep docs generation in CI.
- Pagination provides predictable behavior for large result sets.
- Bidirectional sync requires careful handling of concurrent edits.

## Alternatives considered

- Free-form tool names: harder to discover and document.
- Single-course-only transfer inputs: cannot represent paired equivalencies and leads to incorrect results.
- Offset-based pagination: less efficient for large datasets.
