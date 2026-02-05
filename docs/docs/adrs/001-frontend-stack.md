---
title: ADR-001 - Frontend Stack and Source
description: React + Vite + TailwindCSS frontend from hackathon repo.
sidebar_position: 2
---

# ADR-001: Frontend Stack and Source

- Status: Accepted
- Date: 2026-02-04

## Context

We have a hackathon implementation that includes a functioning UI. We want to accelerate early product iteration without committing to the hackathon backend.

## Decision

- The frontend stack is React + Vite + TailwindCSS.
- We will initially reuse the existing hackathon frontend from `LMSAIH/xhacks2026` under `/frontend`.
- In this repo, the imported frontend will live at `apps/web`.

## Consequences

- We can ship UI updates quickly while backend architecture is rebuilt.
- We will need to normalize configuration and env vars when importing into `apps/web`.

## Alternatives considered

- Rewrite frontend immediately: higher cost, slower validation.
