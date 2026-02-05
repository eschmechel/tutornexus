---
title: Features
description: Overview of Tutor Nexus features and capabilities.
sidebar_position: 2
---

## Core Features

| Feature | Description |
|---------|-------------|
| **AI Tutoring** | Interactive tutoring sessions powered by AI with voice support |
| **Voice Sessions** | Voice-based tutoring with ElevenLabs STT/TTS |

## AI Tutoring

### Capabilities

- Real-time question answering
- Context-aware responses
- Session history and continuity
- Multi-turn conversations

### Usage

```bash
# Create a session
tncli sessions create --title "Calculus Help"

# Send a message
tncli sessions send "How do I integrate x^2?"
```

### MCP Tools

- `tn_sessions_list` - List user's sessions
- `tn_sessions_create` - Create new session
- `tn_sessions_get` - Get session details
- `tn_sessions_events` - Get session events

## Course Explorer

### Data Sources

- SFU Course Calendar
- SFU Outline Server
- RateMyProfs (via adapter)
- Instructor databases
- UBC Course Calendar
- Langara Course Calendar

### Capabilities

- Search courses by code or name
- View detailed outlines
- Check prerequisites
- View instructor ratings

### MCP Tools

- `tn_courses_search` - Search courses
- `tn_courses_get` - Get course details
- `tn_courses_outline` - Get course outline
- `tn_instructors_get` - Get instructor info

## Transfer Planner

### BC Transfer Guide

Integration with BC Transfer Guide for:

- Course equivalencies
- Program requirements
- Institution matching
- Credit recommendations

### Capabilities

- Resolve single course transfers
- Plan multi-course transfers
- Check program requirements
- Find alternative paths

### MCP Tools

- `tn_transfer_resolve` - Resolve transfer
- `tn_transfer_search` - Search transfers
- `tn_transfer_requirements` - Get requirements

## Voice Sessions

### Architecture

```
User Voice → Cloudflare Stream → Workers → ElevenLabs → AI
     ↓                                              ↓
  Storage ←──────────── Transcript ────────────── Response
```

### Features

- Real-time transcription
- Multiple voice options
- Session recording
- Transcript export

### MCP Tools

- `tn_voice_transcript` - Get session transcript
- `tn_voice_config` - Configure voice settings

## User Management

### Authentication

Supports multiple providers:

- Google OAuth
- GitHub OAuth
- Email/Password (Lucia Auth)

### Quotas

| Plan | Prompts /Day |
|------|-------------|
| Anonymous | 10 | 
| Free | 100 |
| Paid | 500 |
| BYOK | Unlimited* |

*Voice Prompts is limited to 500 on BYOK plans

### BYOK (Bring Your Own Key)

Use your own API keys for unlimited access:

```typescript
await client.user.byok.configure({
  provider: 'openai',
  apiKey: userKey,
});
```

## Integrations

### MCP Server

Connect via MCP protocol:

```json
{
  "mcpServers": {
    "tutor-nexus": {
      "command": "tn-mcp",
      "args": ["--api-key", "..."]
    }
  }
}
```

### CLI Tool

```bash
# Install CLI
cargo install tn-cli

# Authenticate
tncli login 

# Configure
tncli config set api-key <key>

# Use
tncli courses search "machine learning"
```

### REST API

Full REST endpoints for custom integrations:

- `GET /api/v1/sessions`
- `POST /api/v1/sessions`
- `GET /api/v1/courses`
- `POST /api/v1/transfer/resolve`

## See Also

- [API Reference](/docs/reference/api)
- [Quick Start](/docs/guides/quickstart)
- [Development Guide](/docs/guides/development)
