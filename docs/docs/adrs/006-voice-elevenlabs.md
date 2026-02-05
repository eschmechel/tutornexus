---
title: ADR-006 - Voice (STT/TTS) via ElevenLabs
description: ElevenLabs STT/TTS with server-side implementation.
sidebar_position: 7
---

# ADR-006: Voice (STT/TTS) via ElevenLabs

- Status: Accepted
- Date: 2026-02-04

## Context

We want voice tutoring as a premium-quality feature, with predictable vendor behavior and server-side control.

## Decision

- Use ElevenLabs for STT and TTS.
- Implement voice server-side only.
- Do not offer voice to anonymous users.

## Consequences

- We must broker audio streaming through the backend.
- Quota and abuse controls must cover voice usage.

## Alternatives considered

- Client-side direct-to-vendor: less control and harder to enforce quotas.
