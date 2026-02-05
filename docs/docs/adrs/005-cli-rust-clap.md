---
title: ADR-005 - CLI/REPL in Rust using clap
description: Rust CLI with clap for argument parsing and REPL mode.
sidebar_position: 6
---

# ADR-005: CLI/REPL in Rust using clap

- Status: Accepted
- Date: 2026-02-04

## Context

We want a fast, portable CLI and REPL to interact with Tutor Nexus services (including MCP), with optional offline workflows.

## Decision

- Implement CLI/REPL in Rust.
- Use `clap` for argument parsing.

## Consequences

- Rust is part of the core stack.
- CLI can implement optional offline/edge workflows independent of the web UI.

## Alternatives considered

- Node-based CLI: faster to prototype but less portable and potentially heavier runtime burden.
