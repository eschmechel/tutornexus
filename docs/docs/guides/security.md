---
title: Security Guide
description: Security practices and OWASP 2025 alignment for Tutor Nexus.
sidebar_position: 5
---

This guide documents security practices aligned with [OWASP Top 10 2025](https://owasp.org/Top10/2025/en/) and outlines the project's defense-in-depth strategy.

## Security Overview

Tutor Nexus implements defense-in-depth security with:

| Layer | Technology | OWASP Category |
|-------|------------|----------------|
| Authentication | Lucia Auth + OAuth | A07 |
| Authorization | RBAC + resource ownership | A01 |
| Encryption | Envelope encryption (KEK/DEK) | A02 |
| Input Validation | Zod schemas | A03 |
| Infrastructure | Cloudflare edge | A05 |
| Dependencies | Dependabot + pnpm audit | A06 |

## OWASP Top 10 2025

### A01:2025 - Broken Access Control

Access control violations are prevented through:

**Role-Based Access Control (RBAC):**

```typescript
// Define roles
const ROLES = {
  USER: 'user',
  TUTOR: 'tutor',
  ADMIN: 'admin',
} as const;

// Check permissions
function requireRole(session: Session, requiredRole: Role) {
  if (session.role === ADMIN) return;
  if (session.role !== requiredRole) {
    throw new AuthorizationError('Insufficient permissions');
  }
}

// Protected route
router.use('/admin/*', (c, next) => {
  const session = await getSession(c);
  requireRole(session, ADMIN);
  return next();
});
```

**Resource Ownership:**

```typescript
async function requireOwnership(
  db: D1Database,
  userId: string,
  resourceId: string
): Promise<boolean> {
  const resource = await db
    .prepare('SELECT user_id FROM resources WHERE id = ?')
    .bind(resourceId)
    .first();
  
  return resource?.user_id === userId;
}
```

### A02:2025 - Cryptographic Failures

All sensitive data uses envelope encryption [ADR-007](/docs/adrs/byok-envelope-encryption):

```typescript
// packages/crypto/src/envelope.ts
import { encrypt, decrypt } from '@tutor-nexus/crypto';

const KEK = await generateKey();

// Encrypt with DEK + KEK
async function encryptCredential(plaintext: string): Promise<Encrypted> {
  const dek = await generateDataKey();
  const encrypted = await encrypt(plaintext, dek);
  const wrapped = await wrapKey(dek, KEK);
  
  return {
    ciphertext: encrypted,
    wrappedKey: wrapped,
    version: CURRENT_VERSION,
  };
}
```

**Secrets never logged or exposed in error messages.**

### A03:2025 - Injection

All input validated with Zod:

```typescript
import { z } from '@hono/zod-openapi';

const CreateSessionSchema = z.object({
  title: z.string().min(1).max(200),
  subject: z.string().optional(),
  description: z.string().max(2000).optional(),
});

router.post('/sessions', zValidator('json', CreateSessionSchema), (c) => {
  const body = c.req.valid('json');
});
```

**Database queries use prepared statements only:**

```typescript
// ✅ Correct - prepared statement
const user = await db
  .prepare('SELECT * FROM users WHERE id = ?')
  .bind(userId)
  .first();

// ❌ Never - string concatenation
const user = await db.prepare(`SELECT * FROM users WHERE id = ${userId}`);
```

### A04:2025 - Insecure Design

Security is addressed at the architecture level through:

- [ADR-001: Project Topology](/docs/adrs/repo-topology-subtrees)
- [ADR-007: BYOK Encryption](/docs/adrs/byok-envelope-encryption)
- [ADR-009: Lucia Auth](/docs/adrs/auth-lucia)
- [ADR-015: Key Rotation](/docs/adrs/byok-crypto-rotation)

Threat modeling performed during ADR review process.

### A05:2025 - Security Misconfiguration

**Cloudflare Security Features:**

```toml
# wrangler.toml
[vars]
NODE_ENV = "production"

[http_features]
security_header = true
bot_management = true
```

**CORS Configuration:**

```typescript
const cors = cors({
  origin: [
    'https://tutor-nexus.com',
    'https://staging.tutor-nexus.com',
  ],
  credentials: true,
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
});
```

### A06:2025 - Vulnerable Components

**Dependency Scanning:**

```bash
# Automated via GitHub Actions
pnpm audit --prod

# With severity threshold
pnpm audit --prod --severity=high
```

**CI Security Checks:**

| Check | Tool | Frequency |
|-------|------|-----------|
| Dependency audit | pnpm audit | Every PR |
| SAST | CodeQL | Every PR |
| Dependency review | GitHub Action | Every PR |
| Secret scanning | TruffleHog | Every PR |

### A07:2025 - Identification Failures

**Lucia Auth Configuration:**

```typescript
export function createLucia(db: D1Database) {
  const adapter = new D1Adapter(db, {
    user: 'users',
    session: 'sessions',
  });
  
  return new Lucia(adapter, {
    sessionCookie: {
      attributes: {
        secure: !isDev,
        sameSite: 'lax',
      },
    },
    getUserAttributes: (attributes) => {
      return {
        email: attributes.email,
        role: attributes.role,
      };
    },
  });
}
```

**OAuth Providers:**

```typescript
// Google OAuth
const googleAuth = new GoogleAuth(clientID, clientSecret, redirectURI);

// GitHub OAuth
const githubAuth = new GitHubAuth(clientID, clientSecret, redirectURI);
```

### A08:2025 - Software/Data Integrity Failures

**CI Verification:**

- All commits verified via GitHub Actions
- Dependency integrity checks (`pnpm dedupe --verify`)
- Build reproducibility verification

### A09:2025 - Security Logging Failures

**Audit Logging:**

```typescript
import { log } from '@tutor-nexus/logger';

log.info('user.login', {
  userId: session.userId,
  timestamp: new Date().toISOString(),
  ip: c.ip,
});
```

### A10:2025 - Unsafe Consumption

**Sanitized API Calls:**

```typescript
// Sanitize external input
const sanitizedQuery = sanitize(input);

// Use typed API clients
const courseData = await courseClient.get({
  validate: true,
  timeout: 5000,
});
```

## API Security

### Rate Limiting

```typescript
import { rateLimit } from '@hono-rate-limiter/cloudflare';

const limiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100, // 100 requests per minute
  keyGenerator: (c) => {
    const session = c.get('session');
    return session?.userId ?? c.ip ?? 'anonymous';
  },
});

app.use('/api/*', limiter);
```

### CSRF Protection

```typescript
app.use('/api/*', (c, next) => {
  const origin = c.req.header('origin');
  const allowedOrigins = ['https://tutor-nexus.com', 'http://localhost:5173'];
  
  if (!origin || !allowedOrigins.includes(origin)) {
    return c.text('Forbidden', 403);
  }
  
  return next();
});
```

## Secrets Management

### Environment Variables

```bash
# Never commit secrets to git
.env.example        # Template (committed)
.env.local          # Developer-specific (gitignored)
.env.production     # Secrets (gitignored)
```

### Cloudflare Secrets

```bash
# Set production secrets via Wrangler
wrangler secret put AUTH_SECRET
wrangler secret put DATABASE_URL
wrangler secret put OPENAI_API_KEY
```

## Security Checklist

- [ ] Enable 2FA on all accounts
- [ ] Use strong, unique passwords
- [ ] Rotate API keys quarterly
- [ ] Review access logs weekly
- [ ] Update dependencies monthly
- [ ] Run security audits quarterly
- [ ] Penetration test annually
- [ ] Verify PGP key fingerprint before use

## Reporting Security Issues

For responsible disclosure of security vulnerabilities, see our [SECURITY.md](https://github.com/eschmechel/tutornexus/blob/main/SECURITY.md) or email `security@tutor-nexus.com`.

**PGP Key:** See `.well-known/pgp-key.txt` for the full public key.

## See Also

- [ADR-007: BYOK Encryption](/docs/adrs/byok-envelope-encryption)
- [ADR-009: Auth](/docs/adrs/auth-lucia)
- [ADR-015: Key Rotation](/docs/adrs/byok-crypto-rotation)
- [OWASP Top 10 2025](https://owasp.org/Top10/2025/en/)
