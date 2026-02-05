---
title: ADR-017 - Transfer Data Model and BCTransferGuide
description: LHS→RHS rules, OR/N-of groups, BCTransferGuide integration.
sidebar_position: 18
---

# ADR-017: Transfer Data Model and BCTransferGuide Adapter

- Status: Accepted
- Date: 2026-02-04

## Context

Transfers are not just 1:1 course mappings.

Requirements:

- paired/multi-course equivalencies (e.g., A + B together -> C)
- generic credit targets (e.g., `CPSC 1XX (3 credits)`)
- elective credit targets
- credit conversion (source credits may differ from target credits)
- effective term/date ranges and evidence references
- "choose one of" and "choose N of" requirements

We also want a BCTransferGuide adapter that ingests transfer information and maps it into a unified normalized model.

## Decision

### Storage location

Transfer rules stored in separate D1 database: `tn-transfers`

**Rationale:**
- Clean separation from course catalog
- Different access patterns
- Allows independent scaling
- Matches adapter architecture

### Normalized equivalency model

Represent transfer equivalencies as rules:

- Left-hand side (LHS): a set of required source course references
- Right-hand side (RHS): a target credit descriptor of type `course | generic | elective`

**LHS supports:**
- Required courses (AND semantics)
- OR groups ("choose one of")
- N-of groups ("choose N of")

**RHS types:**

| Type | Description | Example |
|------|-------------|---------|
| `course` | Specific target course | `"ubc:CPSC 221"` |
| `generic` | Pattern-based credit | `"CPSC 1XX"` |
| `elective` | Elective bucket | `"science_elective"` |

### Rule schema

```typescript
interface TransferRule {
  ruleId: ULID;
  sourceInstitution: string;      // "sfu", "langara", etc.
  targetInstitution: string;      // "ubc", "uvic", etc.
  lhs: {
    type: "required" | "or_group" | "n_of";
    courses: string[];            // Course references
    n?: number;                   // Required count for "n_of"
  }[];
  rhs: {
    type: "course" | "generic" | "elective";
    courseRef?: string;           // For "course"
    pattern?: string;             // For "generic" (e.g., "CPSC 1XX")
    bucket?: string;              // For "elective" (e.g., "science_elective")
    credits: number;              // Target credits
  };
  effectiveStart?: string;        // Term code (e.g., "2024F") or date
  effectiveEnd?: string;
  evidence: {
    title: string;                // e.g., "SFU to UBC Transfer Guide"
    url: string;
    accessDate: string;           // RFC3339
    section?: string;             // Specific section referenced
  }[];
  confidence: number;             // 0.0 to 1.0
  notes?: string;
  createdAt: string;
  updatedAt: string;
}
```

### Resolution algorithm

**Exact match:**
- All required LHS courses are present in user's courses
- OR groups satisfied if any option is present
- N-of groups satisfied if at least N courses are present

**Partial match:**
- Overlap between LHS and user's courses
- Report missing courses
- Report which OR options are satisfied
- Report progress toward N-of groups

### Evidence and attribution

All transfer rules must include full citation objects:

```typescript
interface Evidence {
  source: string;        // e.g., "BC Transfer Guide"
  url: string;           // Direct link to transfer rule
  accessedAt: string;   // RFC3339
  excerpt?: string;      // Optional quote from source
}
```

**Attribution requirement:**
When displaying transfer information, attribute BC Transfer Guide as the source.

### Storage architecture

```
D1 Databases:
- tn-sessions      (auth, users, quotas, BYOK)
- tn-courses       (normalized course catalog)
- tn-transfers     (unified transfer rules)
- tn-adapter-sfu   (raw SFU data)
- tn-adapter-langara (raw Langara data)
- tn-adapter-bctransfer (raw BC Transfer Guide data)
```

**Query flow for `tn_transfer_resolve`:**
1. Look up transfers in `tn-transfers`
2. Match against user's courses
3. Return exactMatches + partialMatches
4. Include full evidence citations

### Support for complex requirements

**"Choose one of" (OR groups):**
```typescript
{
  type: "or_group",
  courses: ["sfu:MATH 100", "sfu:MATH 190"]
}
// Satisfied if user has either MATH 100 OR MATH 190
```

**"Choose N of":**
```typescript
{
  type: "n_of",
  courses: ["sfu:CMPT 120", "sfu:CMPT 125", "sfu:CMPT 127"],
  n: 2
}
// Satisfied if user has at least 2 of the 3 courses
```

## Consequences

- Queries and indexes must support set membership efficiently.
- MCP and API responses can explain partial matches.
- Attribution requirement affects UI display.
- BC Transfer Guide adapter must respect source attribution.

## Alternatives considered

- Only 1:1 transfer mappings: insufficient.
- Encode multi-course equivalencies as text notes: not machine-usable.
- Store transfers in `tn-courses`: couples schema evolution.

## Implementation notes

- Index on `(sourceInstitution, targetInstitution)` for fast lookup.
- Consider GIN index on course arrays for set matching.
- BC Transfer Guide ingestion requires ToS compliance.
