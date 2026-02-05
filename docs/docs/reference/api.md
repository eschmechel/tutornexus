---
title: API Reference
description: Complete API reference for Tutor Nexus.
sidebar_position: 1
---

The Tutor Nexus API is built on Cloudflare Workers with Hono and follows OpenAPI 3.0 specifications.

## Base URL

| Environment | URL |
|-------------|-----|
| Production | `https://api.tutor-nexus.com` |
| Staging | `https://staging.api.tutor-nexus.com` |
| Local | `http://localhost:8787` |

## Authentication

All API requests require authentication via Lucia Auth session cookie or Bearer token.

```bash
# Session cookie (browser)
curl -H "Cookie: lucia_session=..." https://api.tutor-nexus.com/api/v1/sessions

# Bearer token (CLI)
curl -H "Authorization: Bearer <token>" https://api.tutor-nexus.com/api/v1/sessions
```

## Rate Limits

| Tier | Requests/Day | Requests/Minute |
|------|--------------|-----------------|
| Anonymous | 10 | 1 |
| Free | 100 | 10 |
| Paid | 500 | 60 |
| BYOK | Unlimited | 100 |

## API Versioning

Current version: `v1`

API versions are URL-prefixed: `/api/v1/`

## Endpoints

| Endpoint | Description |
|----------|-------------|
| **Sessions** | Create and manage tutoring sessions |
| **Courses** | Browse course outlines and instructors |
| **Transfers** | Resolve transfer credit rules |
| **Users** | User profiles and settings |

## OpenAPI Documentation

Interactive API documentation available at:

- Swagger UI: `https://api.tutor-nexus.com/docs`
- ReDoc: `https://api.tutor-nexus.com/redoc`

## SDKs

Official and community SDKs for easier integration:

| Language | Package | Purpose |
|----------|---------|---------|
| TypeScript | `@tutor-nexus/sdk` | Primary SDK for web/Node.js apps |
| Python | `tutor-nexus-py` | Data science and scripting |
| Go | `github.com/tutornexus/mcp` | MCP server for IDE integration |

SDKs are auto-generated from the OpenAPI spec at build time.

## Error Handling

All errors follow RFC 7807 Problem Details:

```json
{
  "type": "https://api.tutor-nexus.com/errors/validation",
  "title": "Validation Error",
  "status": 400,
  "detail": "Invalid course ID format",
  "instance": "/api/v1/courses/cmpt-120",
  "errors": [
    {
      "field": "courseId",
      "message": "Must match pattern: ^[A-Z]{3,4} \\d{3}$"
    }
  ]
}
```

## Quick Reference

```typescript
import { TutorNexus } from '@tutor-nexus/sdk';

const client = new TutorNexus({
  apiKey: process.env.TUTOR_NEXUS_API_KEY,
});

// List sessions
const sessions = await client.sessions.list({
  limit: 10,
  status: 'active',
});

// Get a course
const course = await client.courses.get('CMPT 120');

// Resolve transfer
const transfer = await client.transfers.resolve({
  sourceCourse: 'CMPT 120',
  sourceInstitution: 'sfu',
  targetInstitution: 'ubc',
});
```

## See Also

- [Features](/docs/reference/features)
- [Quick Start](/docs/guides/quickstart)
- [Security Guide](/docs/guides/security)
