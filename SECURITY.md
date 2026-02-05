# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest | ✅ |
| Previous | ✅ |
| Older | ❌ |

## Reporting a Vulnerability

### Private Vulnerability Reporting

We encourage responsible disclosure of security vulnerabilities. You can report vulnerabilities in two ways:

**1. GitHub Private Vulnerability Reporting**
- Click "Report a vulnerability" on the Security tab
- Allows private discussion before disclosure

**2. Encrypted Email (PGP)**

For encrypted communications, use the PGP key below:

```
-----BEGIN PGP PUBLIC KEY BLOCK-----

tutor-nexus-security

-----END PGP PUBLIC KEY BLOCK-----
```

*See `.well-known/pgp-key.txt` for the full public key.*

### What to Include

When reporting a vulnerability, please include:

1. **Description** - What the vulnerability is
2. **Steps to reproduce** - How to trigger the issue
3. **Impact** - What an attacker could accomplish
4. **Severity** - Your assessment (Critical, High, Medium, Low)
5. **Contact** - Your email for follow-up

### Response Timeline

| Action | Timeline |
|--------|----------|
| Initial acknowledgment | 24 hours |
| Severity assessment | 48 hours |
| Status update | Weekly |
| Resolution | Based on severity |

## Scope

This policy applies to:

- **API endpoints** (`/api/*`)
- **Authentication and authorization** flows
- **Credential encryption** (BYOK system)
- **MCP server** security
- **CLI tool** security
- **Web application** security

### Out of Scope

- Social engineering attacks
- Physical security
- Third-party services not controlled by Tutor Nexus
- Vulnerability in an already documented known issue

## Coordinated Disclosure

We follow responsible disclosure practices:

1. Reporters will be credited (unless they request anonymity)
2. We coordinate fix timelines based on severity
3. Security advisories are published after fixes are deployed
4. CVEs are requested for significant vulnerabilities

## OWASP Top 10 2025 Alignment

This project addresses the following OWASP 2025 categories:

| Category | Protection |
|----------|------------|
| A01:2025 - Broken Access Control | RBAC, resource ownership checks |
| A02:2025 - Cryptographic Failures | Envelope encryption (KEK/DEK) |
| A03:2025 - Injection | Zod validation, parameterized queries |
| A04:2025 - Insecure Design | ADRs document threat modeling |
| A05:2025 - Security Misconfiguration | Cloudflare edge security, CORS |
| A06:2025 - Vulnerable Components | Dependabot, pnpm audit, CodeQL |
| A07:2025 - Identification Failures | Lucia Auth, OAuth 2.0 |
| A08:2025 - Software/Data Integrity Failures | Signed commits, CI verification |
| A09:2025 - Security Logging Failures | Structured logging, audit trails |
| A10:2025 - Unsafe Consumption | Sanitized third-party API calls |

## Recognition

Responsible security researchers will be recognized in our security hall of fame (unless you opt out).

Thank you for helping keep Tutor Nexus secure!
