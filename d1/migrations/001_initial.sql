-- Tutor Nexus D1 Database Migrations
-- Database: tn-sessions

-- ============================================
-- Migration 001: Initial Schema
-- ============================================

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    hashed_password TEXT,
    provider TEXT,  -- 'email', 'github', 'google', null
    provider_id TEXT,
    tier TEXT DEFAULT 'free' CHECK(tier IN ('anonymous', 'free', 'paid')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Create sessions table
CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    status TEXT DEFAULT 'active' CHECK(status IN ('active', 'paused', 'ended')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    expires_at TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Create session_events table
CREATE TABLE IF NOT EXISTS session_events (
    id TEXT PRIMARY KEY,
    session_id TEXT NOT NULL,
    seq INTEGER NOT NULL,
    type TEXT NOT NULL,
    created_at TEXT NOT NULL,
    actor_user_id TEXT,
    client_event_id TEXT NOT NULL,
    payload_json TEXT NOT NULL,
    is_pending INTEGER DEFAULT 0 CHECK(is_pending IN (0, 1)),
    FOREIGN KEY (session_id) REFERENCES sessions(id)
);

-- Create unique index for idempotency
CREATE UNIQUE INDEX IF NOT EXISTS idx_events_idempotency
    ON session_events(session_id, client_event_id);

-- Create index for session sequencing
CREATE INDEX IF NOT EXISTS idx_session_events_session_seq
    ON session_events(session_id, seq);

-- Create quota_usage table
CREATE TABLE IF NOT EXISTS quota_usage (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    ip_hash TEXT,
    tier TEXT NOT NULL CHECK(tier IN ('anonymous', 'free', 'paid')),
    date TEXT NOT NULL,  -- YYYY-MM-DD
    prompts_used INTEGER DEFAULT 0,
    last_updated TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Create index for quota lookups
CREATE INDEX IF NOT EXISTS idx_quota_lookup
    ON quota_usage(user_id, date);
CREATE INDEX IF NOT EXISTS idx_quota_anonymous
    ON quota_usage(ip_hash, date);

-- Create byok_credentials table
CREATE TABLE IF NOT EXISTS byok_credentials (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    provider TEXT NOT NULL CHECK(provider IN ('openai', 'ollama')),
    encrypted_payload TEXT NOT NULL,
    wrapped_dek TEXT NOT NULL,
    kek_version TEXT NOT NULL,
    display_name TEXT NOT NULL,
    is_active INTEGER DEFAULT 1 CHECK(is_active IN (0, 1)),
    last_used_at TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Create index for user credentials
CREATE INDEX IF NOT EXISTS idx_byok_user
    ON byok_credentials(user_id, provider);

-- ============================================
-- Migration 002: Snapshots
-- ============================================

-- Create snapshots table
CREATE TABLE IF NOT EXISTS session_snapshots (
    id TEXT PRIMARY KEY,
    session_id TEXT NOT NULL,
    base_snapshot_id TEXT,
    from_seq INTEGER NOT NULL,
    to_seq INTEGER NOT NULL,
    events_json TEXT NOT NULL,
    ai_summary TEXT,
    created_at TEXT NOT NULL,
    FOREIGN KEY (session_id) REFERENCES sessions(id),
    FOREIGN KEY (base_snapshot_id) REFERENCES session_snapshots(id)
);

-- Create index for snapshot lookups
CREATE INDEX IF NOT EXISTS idx_snapshots_session
    ON session_snapshots(session_id, to_seq);

-- ============================================
-- Migration 003: AI Summaries
-- ============================================

-- Create ai_summaries table
CREATE TABLE IF NOT EXISTS ai_summaries (
    id TEXT PRIMARY KEY,
    session_id TEXT NOT NULL,
    from_seq INTEGER NOT NULL,
    to_seq INTEGER NOT NULL,
    summary_text TEXT NOT NULL,
    key_topics TEXT NOT NULL,  -- JSON array
    action_items TEXT NOT NULL,  -- JSON array
    generated_by TEXT NOT NULL,  -- 'hourly', 'user', 'session_end'
    cooldown_used INTEGER DEFAULT 0 CHECK(cooldown_used IN (0, 1)),
    created_at TEXT NOT NULL,
    FOREIGN KEY (session_id) REFERENCES sessions(id)
);

-- Create index for summary lookups
CREATE INDEX IF NOT EXISTS idx_summaries_session
    ON ai_summaries(session_id, created_at);

-- ============================================
-- Migration 004: User Preferences
-- ============================================

-- Create user_preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
    user_id TEXT PRIMARY KEY,
    theme TEXT DEFAULT 'system' CHECK(theme IN ('light', 'dark', 'system')),
    voice_enabled INTEGER DEFAULT 0 CHECK(voice_enabled IN (0, 1)),
    voice_id TEXT,
    language TEXT DEFAULT 'en',
    notifications INTEGER DEFAULT 1 CHECK(notifications IN (0, 1)),
    updated_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ============================================
-- Views for Common Queries
-- ============================================

-- View: Active sessions with user info
CREATE VIEW IF NOT EXISTS active_sessions_view AS
SELECT
    s.id as session_id,
    s.status,
    s.created_at,
    s.expires_at,
    u.id as user_id,
    u.email,
    u.tier,
    COUNT(e.id) as event_count
FROM sessions s
LEFT JOIN users u ON s.user_id = u.id
LEFT JOIN session_events e ON s.id = e.session_id
WHERE s.status IN ('active', 'paused')
GROUP BY s.id;

-- View: Daily quota summary
CREATE VIEW IF NOT EXISTS daily_quota_summary AS
SELECT
    user_id,
    tier,
    date,
    SUM(prompts_used) as total_prompts
FROM quota_usage
GROUP BY user_id, date;

-- ============================================
-- Triggers for updated_at
-- ============================================

CREATE TRIGGER IF NOT EXISTS users_updated_at
    AFTER UPDATE ON users
BEGIN
    UPDATE users SET updated_at = datetime('now') WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS sessions_updated_at
    AFTER UPDATE ON sessions
BEGIN
    UPDATE sessions SET updated_at = datetime('now') WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS byok_updated_at
    AFTER UPDATE ON byok_credentials
BEGIN
    UPDATE byok_credentials SET updated_at = datetime('now') WHERE id = NEW.id;
END;
