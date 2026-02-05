---
title: ADR-004 - MCP Server in Go (Official SDK)
description: Go 1.25 MCP server with official SDK and structured logging.
sidebar_position: 5
---

# ADR-004: MCP Server in Go (Official SDK)

- Status: Accepted
- Date: 2026-02-04

## Context

We want a reliable MCP server with strong performance, a small dependency graph, and a clear contract for tools.

## Decision

- Implement the MCP server in Go.
- Target Go version: 1.25.x.
- Use the official MCP Go SDK: `github.com/modelcontextprotocol/go-sdk`.
- Use `log/slog` for structured logging.
- Implement configs and binary releases for local mcp hosting
- Main MCP server deployed to either Fly.io or CF Workers (Wasm), with render deployment for previews

## Consequences

- Go becomes a first-class language in the project.
- Tool schemas should be centralized and used to generate docs.

## Alternatives considered

- Implement MCP server in TypeScript: easier staffing initially, but less separation from Workers and fewer deployment options.
