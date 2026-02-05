---
title: ADR-014 - Voice Pipeline (Streaming STT/TTS)
description: WebSocket streaming, 16kHz audio, transcript persistence.
sidebar_position: 15
---

# ADR-014: Voice Pipeline (Streaming STT/TTS)

- Status: Accepted
- Date: 2026-02-04

## Context

Voice tutoring is a core differentiator but has higher cost and higher abuse risk than text.

Constraints:

- Voice must be server-side only.
- Voice is not available to anonymous users.
- STT and TTS vendor: ElevenLabs.
- Live session coordination uses Durable Objects [ADR-013](./013-live-session-state-durable-objects.md).

We want low-latency streaming behavior with predictable persistence and retention:

- Do not store raw audio by default.
- Persist transcripts and structured metadata in D1 as session events.

## Decision

### Architecture

- Web client connects to the session Durable Object (DO) via WebSocket.
- Client streams microphone audio frames to the DO.
- DO brokers streaming STT with ElevenLabs and emits transcript events.
- Assistant responses are generated as text first; TTS is then synthesized and streamed back to the client.

Audio format requirements:

- Client captures audio at 16kHz sample rate, mono, 16-bit PCM.
- Audio is chunked into frames (e.g., 100-500ms) and streamed over WebSocket.
- DO may implement server-side Voice Activity Detection (VAD) to reduce noise.

### Data persistence

- Raw audio is treated as ephemeral and is not written to D1.
- The following are persisted as session events:
  - transcript partials/finals (with timestamps)
  - assistant text output
  - voice generation metadata (voice id, duration, cost/usage counters)

Event schema for transcripts:

```typescript
interface TranscriptEvent {
  eventType: "transcript_partial" | "transcript_final";
  sessionId: ULID;
  sequence: number;
  timestamp: RFC3339;
  role: "user" | "assistant";
  text: string;
  audioOffsetMs: number; // position in audio stream
}
```

### Quotas and gating

- Voice requires a signed-in user.
- Quota checks occur before accepting sustained audio streaming.
- Usage accounting records:
  - number of prompts
  - voice seconds/minutes (tracked separately per session)
- Voice quota resets on the same schedule as text prompts.

### Failure behavior

- If the STT stream fails, the DO notifies the client and falls back to text input.
- If TTS fails, the DO returns text-only response.
- Client may retry voice input after a brief backoff.

### Voice selection

- Users may select a preferred voice from available ElevenLabs voices.
- Voice preference is stored per-user in D1 (`tn-sessions`).
- Default voice is used if user preference is not set.

## Consequences

- Session DO implementation must support bidirectional streaming.
- We need clear event types for transcript segments and voice metadata.
- Quota enforcement must account for sustained connections.
- Additional load on ElevenLabs API requires careful cost monitoring.

## Alternatives considered

- Client-side direct-to-ElevenLabs: harder quotas, leaks vendor boundaries, weaker abuse control.
- Storing raw audio: higher privacy risk and storage costs.
- Batch transcription instead of streaming: higher latency, worse UX.

## Implementation notes

- ElevenLabs streaming API should be used when available; otherwise, chunked audio.
- Implement exponential backoff for API rate limits.
- Log errors without including any audio content.
- Voice support in CLI is optional for MVP; can be added in Phase 2.
