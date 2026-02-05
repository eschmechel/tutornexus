---
title: ADR-000 - Repository Topology and Subtree Vendoring
description: Git subtrees strategy for vendoring MCP, adapters, CLI repos.
sidebar_position: 1
---

# ADR-000: Repository Topology and Subtree Vendoring

- Status: Accepted
- Date: 2026-02-04

## Context

Tutor Nexus spans multiple components (web app, Workers API, MCP server, adapters/scrapers, CLI). We want:

- clean separation of concerns (each component can evolve independently)
- strong governance in a single integration repo
- the ability to develop and ship with a coherent versioned snapshot

We also want to avoid fragile mono-repo tooling that obscures ownership and history.

## Decision

We will maintain multiple public repos and vendor them into the integration repo via git subtrees ("Option A").

Integration repo: `eschmechel/tutornexus`.

Vendored prefixes (planned):

- `services/mcp` from `eschmechel/mcp-tutornexus`
- `services/adapters` from `eschmechel/adapters-tutornexus`
- `tools/cli` from `eschmechel/cli-tutornexus` (optional but planned)

Subtree adds/updates should be performed with `--squash` to keep the integration history readable.

## Consequences

- The integration repo can pin coherent versions of each service.
- Each service repo retains its own CI, release cadence, and issue tracker.
- Subtree updates require disciplined commands and occasional conflict resolution.

## Alternatives considered

- Single mono-repo without subtrees: simpler checkouts, but tighter coupling and noisier history.
- Git submodules: easy pointers but more footguns for contributors and CI.
