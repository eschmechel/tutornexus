---
title: ADR-018 - Quotas and Entitlements
description: Anonymous 10/day, Free 100/day, Paid 500/day, BYOK unlimited.
sidebar_position: 19
---

# ADR-018: Quotas and Entitlements

- Status: Accepted
- Date: 2026-02-04

## Context

We need quotas to control cost and abuse across text and voice.

Decisions already made:

- Anonymous: 10 prompts/day per IP
- Free signed-in: 100 prompts/day per user
- Paid: 500 prompts/day per user
- Voice is not available to anonymous users
- Subscriptions are managed via Polar [ADR-010](010-billing-polar-kofi.md)

## Decision

### Quota tiers

| Tier | Prompts/day | Voice | Access |
|------|-------------|-------|--------|
| Anonymous | 10 | No | IP-hashed |
| Free | 100 | Yes (counts as prompts) | Authenticated user |
| Paid | 500 | Yes (counts as prompts) | Authenticated + Polar subscription |

### What is counted

- **Prompt**: Any user-originated request that triggers an LLM call.
- **Voice request**: Counts as 1 prompt (voice seconds tracked separately for analytics).
- **Streaming response**: Still counts as 1 prompt total, not per-token.
- **Partial/retry requests**: Free up to 3 attempts per user action. After 3 retries, additional attempts count as new prompts.

### Reset boundary

- **UTC midnight**: Quotas reset at 00:00 UTC each day.
- Rationale: Simpler implementation, consistent behavior across timezones.

### BYOK policy

- **BYOK usage is unlimited** (user pays for their own API usage).
- Quota limits apply to Tutor Nexus platform calls (RAG, MCP tools, etc.), not to user's own LLM API calls.
- Rationale: BYOK users already pay for API costs; limiting their usage adds friction without reducing platform costs.

### Voice entitlements

- Voice requests count against the same prompt quota.
- No separate voice minute allocation.
- Rationale: Simpler quota management.

### Enforcement

- **Authoritative quota usage** stored in D1 (`tn-sessions`).
- **Preflight checks**: DO performs quota verification before accepting requests.
- **Rate limiting**: DO enforces per-connection rate limits.
- **Concurrency safety**: Usage increments use idempotent keys (prevents double-counting).

### Identity keys

| Tier | Key type | Example |
|------|----------|---------|
| Anonymous | IP hash (privacy-preserving) | `sha256(ip + salt)` |
| Free | User ID (ULID) | `01HXYZ...` |
| Paid | User ID + subscription ID | `01HXYZ... + sub_ABC...` |

### Quota tracking schema

```typescript
interface QuotaUsage {
  id: ULID;
  userId?: ULID;           // null for anonymous
  ipHash?: string;         // null for authenticated
  tier: "anonymous" | "free" | "paid";
  date: string;            // YYYY-MM-DD (UTC)
  promptsUsed: number;
  lastUpdated: string;     // RFC3339
}

interface QuotaLimit {
  tier: string;
  promptsPerDay: number;
  voiceEnabled: boolean;
}
```

### API response for quota check

```typescript
interface QuotaStatus {
  tier: string;
  promptsRemaining: number;
  promptsTotal: number;
  resetsAt: string;        // RFC3339 UTC
  voiceEnabled: boolean;
}
```

### Example responses

**Within quota:**
```json
{
  "tier": "free",
  "promptsRemaining": 85,
  "promptsTotal": 100,
  "resetsAt": "2026-02-05T00:00:00Z",
  "voiceEnabled": true
}
```

**Over quota:**
```json
{
  "code": "RATE_LIMITED",
  "message": "Daily prompt limit exceeded",
  "details": {
    "reason": "User has used 100/100 prompts today",
    "retryAfter": 43200,
    "limit": {
      "current": 100,
      "max": 100,
      "window": "day"
    }
  },
  "requestId": "01JXYZ123ABC"
}
```

## Consequences

- Clear, predictable quota behavior for users.
- Simpler implementation (UTC midnight reset).
- BYOK users have frictionless experience.
- Voice integrated naturally into existing quota system.

## Alternatives considered

- Token-based quotas: more accurate but harder to explain and implement early.
- Local timezone reset: better UX but more complex implementation.
- BYOK quotas: adds friction without platform benefit.

## Implementation notes

- IP hash should use per-deployment salt for privacy.
- Quota checks must be fast (cache frequently accessed data in DO).
- Consider graduated rate limiting (warn at 80%, block at 100%).
