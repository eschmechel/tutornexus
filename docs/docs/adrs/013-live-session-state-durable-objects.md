---
title: ADR-013 - Live Session State with Durable Objects
description: DO for real-time state, hybrid snapshots, agentic summarization.
sidebar_position: 14
---

# ADR-013: Live Session State using Durable Objects

- Status: Accepted
- Date: 2026-02-04

## Context

Tutor sessions may involve live state (multi-turn chat, streaming voice, reconnects). We need a low-latency state holder that is compatible with Workers and can coordinate ephemeral state while persisting durable history.

We also need clean separation:

- Durable Objects are for live coordination.
- D1 is the durable store of record.
- Bidirectional sync between CLI daemon and webapp must be supported.

## Decision

### Durable Objects for live state

- Use Durable Objects (DO) for live/session state.
- Key DO instances by `session_id` (ULID).
- D1 remains the source of truth for durable session history and auditing.

### Transport

- Text-only clients MAY use standard HTTP routes.
- Live clients (web voice, streaming UI) connect to the session DO over WebSocket.
- CLI daemon syncs via Workers API (Option B: API proxy, not direct DO WebSocket).

### Bidirectional sync (CLI ↔ Webapp)

The session DO serves as the authoritative source for bidirectional sync:

- CLI daemon pushes edits to Workers API → DO
- Webapp polls DO every 60 seconds OR on manual refresh
- Both directions sync to the same DO instance
- Sync occurs on every edit (no polling interval for CLI daemon)

#### Sync tools

| Tool | Purpose |
|------|---------|
| `tn_session_export` | Generate portable snapshot for webapp import |
| `tn_session_sync_status` | Check pending sync status |
| `tn_session_cancel_pending` | Cancel pending/draft messages before send |

#### Pending/draft messages

- Users can draft messages before sending.
- Pending messages can be cancelled before the session processes them.
- Only one pending message per session at a time.

### Persistence model

Use an append-only event log in D1 for each session.

#### Event design goals

- replayable (derive session state from events)
- auditable (who did what, when)
- idempotent (safe retries across network failures)

#### Event fields

```typescript
interface SessionEvent {
  eventId: ULID;          // Server-generated ULID
  sessionId: ULID;        // Session this event belongs to
  seq: number;            // Monotonic integer per session (assigned by DO)
  type: string;           // Event type: message, transcript, etc.
  createdAt: string;      // RFC3339 timestamp
  actorUserId: ULID | null;  // User who caused this event (null for anonymous)
  clientEventId: string;  // Client-generated ID for idempotency
  payloadJson: string;    // JSON payload
  isPending: boolean;      // True for draft/pending messages
}
```

#### D1 table schema

```sql
CREATE TABLE session_events (
  eventId TEXT PRIMARY KEY,
  sessionId TEXT NOT NULL,
  seq INTEGER NOT NULL,
  type TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  actorUserId TEXT,
  clientEventId TEXT NOT NULL,
  payloadJson TEXT NOT NULL,
  isPending INTEGER DEFAULT 0,
  FOREIGN KEY (sessionId) REFERENCES sessions(sessionId)
);

CREATE INDEX idx_session_events_session_seq 
  ON session_events(sessionId, seq);

CREATE UNIQUE INDEX idx_session_events_idempotency 
  ON session_events(sessionId, clientEventId);
```

### Idempotency and ordering

- Clients include `client_event_id` on every client-originated event.
- D1 enforces uniqueness on `(session_id, client_event_id)`.
- The DO assigns a monotonic `seq` for every accepted event and persists it with the event.
- Duplicate `client_event_id` returns the existing event without reprocessing.

### Concurrency handling

Implement in-memory queue for sequential processing of concurrent requests:

- Multiple requests to the same session are queued and processed one at a time.
- Prevents race conditions without rejecting connections.
- DO instances are rarely evicted, so in-memory queue is reliable.
- If DO is evicted, pending queue messages are lost (client must retry).

### Hybrid snapshots

Create snapshots to enable efficient session resume without replaying all events.

#### Snapshot cadence

- Every 5 minutes of session activity OR
- Every 100 events, whichever comes first
- Additionally at session end

#### Snapshot types

**Differential snapshot:**

```typescript
interface DifferentialSnapshot {
  snapshotId: ULID;
  baseSnapshotId: ULID | null;    // References previous snapshot (null for first)
  sessionId: ULID;
  createdAt: string;              // RFC3339
  fromSeq: number;               // Start of this diff
  toSeq: number;                 // End of this diff
  events: SessionEvent[];        // Only new events since base
  aiSummary?: string;            // Optional agentic summary
}
```

**Benefits:**
- Storage efficient (don't duplicate unchanged data)
- Full replay: chain snapshots together
- AI summary at each snapshot for fast context

#### Agentic summarization

Generate AI summaries at snapshot points:

- **Automatic**: Hourly (approximately every 5 minutes based on snapshot cadence)
- **Session end**: Always generate final summary
- **User-triggered**: User can request summary with 5-minute cooldown

```typescript
interface AgenticSummary {
  summaryId: ULID;
  sessionId: ULID;
  createdAt: string;       // RFC3339
  fromSeq: number;         // Events covered
  toSeq: number;
  summaryText: string;     // AI-generated summary
  keyTopics: string[];     // Extracted topics
  actionItems: string[];   // Action items mentioned
}
```

**User-triggered summarization:**

```typescript
// Request
tn_session_summarize({
  sessionId: ULID,
  style: "brief" | "detailed" | "action_items"
});

// Response
{
  summaryId: ULID,
  summaryText: "...",
  keyTopics: ["binary trees", "recursion"],
  actionItems: ["Practice tree traversals"],
  cooldownRemaining: 300  // Seconds until next user-trigger allowed
}
```

### Reconnect/resume

- Client resumes by `session_id`.
- After reconnect, client provides `last_seen_seq`.
- DO sends a catch-up stream of events from the last snapshot + tail events.

**Resume flow:**

```
1. Client connects with session_id + last_seen_seq
2. DO finds most recent snapshot covering last_seen_seq
3. DO loads snapshot + events after snapshot.toSeq
4. DO streams missing events to client
5. Client is now caught up
```

### Quotas and gating

- DO verifies the actor (Lucia session) is authorized for the `session_id`.
- DO performs per-connection rate limiting and backpressure.
- Authoritative quota usage is tracked durably in D1 (e.g., per user/day, per IP/day).
- Quota checks occur before accepting messages.

### Voice coordination

- Voice runs through the session DO for coordination.
- Raw audio is treated as ephemeral and is not written to D1.
- Persist transcripts and structured metadata (timestamps, speaker, etc.) as session events.

### Failure behavior

- If D1 persistence fails, the DO must not silently accept further events.
- The DO should surface an error to the client and require retry/reconnect.
- Snapshot failures should not block event processing.

### Ephemeral in-memory caching

DO instances maintain in-memory caches for performance:

| Cache | Source | TTL | Purpose |
|-------|--------|-----|---------|
| Recent events | D1 event log | 500 events | Fast replay on resume |
| Course catalog | D1 `tn-courses` | 5 minutes | Faster course searches |
| Transfer rules | D1 `tn-courses` | 10 minutes | Faster transfer resolves |
| AI summary | Generated | Until snapshot | Context for new messages |

#### Cache limits

- Maximum 10MB in-memory cache per DO instance
- LRU eviction when limit reached
- Cache key prefixes: `sess:{sessionId}:`, `glob:{dataType}:`

### CLI daemon sync architecture

CLI daemon uses OAuth device flow for authentication:

1. User: `tncli daemon start`
2. CLI: "Visit https://tutor-nexus.com/device to authenticate"
3. User: Opens URL, clicks "Approve"
4. CLI: Receives tokens, starts daemon
5. Daemon: Syncs with DO on every edit via Workers API
6. Daemon: Uses refresh token to stay authenticated

#### Offline support

- CLI daemon detects online/offline state.
- Offline: Daemon writes to local SQLite.
- Online: Daemon syncs local SQLite to DO.
- Conflicts resolved: Server wins; local copy archived.

## Consequences

- We must implement an event schema, idempotency constraints, and differential snapshots.
- DO becomes the coordination point for WebSocket, voice pipelines, and CLI sync.
- Reconnect becomes a first-class workflow.
- Agentic summarization requires AI integration.
- Ephemeral caching improves performance but adds complexity.

## Alternatives considered

- Store live state only in D1: higher latency, harder streaming.
- Store everything only in DO: poor durability guarantees and harder analytics.
- Direct DO WebSocket for CLI: less secure, harder to audit.

## Implementation notes

- Snapshot cadence may need tuning based on real usage patterns.
- Agentic summarization cost should be monitored and may need quota limits.
- CLI daemon offline support can be deferred to Phase 2 if Phase 1 timeline is tight.
