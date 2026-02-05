# Tutor Nexus

Tutor Nexus (tutor-nexus.com) is a tutoring + course-transfer assistant.

This repo is the "integration" monorepo. It will host the web frontend and the Cloudflare Workers API, and vendor related services (MCP server, adapters, CLI) via git subtrees.

## What exists today

Planning + governance docs are the source of truth right now. See:

- `docs/snapshots/2026-02-04-planning-snapshot.md` (full planning snapshot)
- `docs/adr/README.md` (architecture decision records)

## Target architecture (planned)

- `apps/web`: React + Vite + TailwindCSS frontend (initially imported from the hackathon repo)
- `apps/api`: TypeScript Cloudflare Workers backend (Hono + OpenAPI generation)
- `services/mcp`: Go MCP server vendored via subtree
- `services/adapters`: TS adapter pipeline + Cloudflare Queues (vendored via subtree)
- `tools/cli`: Rust CLI/REPL (vendored via subtree)

## Repo strategy

We intentionally vendor external repos via git subtrees ("Option A"). See `docs/adr/000-repo-topology-subtrees.md`.

## Status

Early-stage: no product code imported yet. This repo currently exists to preserve critical requirements and design choices while implementation scaffolding starts.
