-- Tutor Nexus D1 Database Migrations
-- Database: tn-transfers

-- ============================================
-- Migration 001: Transfer Rules Schema
-- ============================================

-- Create transfer_rules table
CREATE TABLE IF NOT EXISTS transfer_rules (
    id TEXT PRIMARY KEY,
    source_institution TEXT NOT NULL,
    target_institution TEXT NOT NULL,
    lhs_json TEXT NOT NULL,  -- JSON: TransferLHS[]
    rhs_json TEXT NOT NULL,  -- JSON: TransferRHS
    effective_start TEXT,    -- Term code or date
    effective_end TEXT,      -- Term code or date
    evidence_json TEXT NOT NULL,  -- JSON: TransferEvidence[]
    confidence REAL DEFAULT 1.0,
    notes TEXT,
    is_active INTEGER DEFAULT 1 CHECK(is_active IN (0, 1)),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Create indexes for transfer lookups
CREATE INDEX IF NOT EXISTS idx_transfers_lookup
    ON transfer_rules(source_institution, target_institution);
CREATE INDEX IF NOT EXISTS idx_transfers_effective
    ON transfer_rules(effective_start, effective_end);
CREATE INDEX IF NOT EXISTS idx_transfers_source
    ON transfer_rules(source_institution);
CREATE INDEX IF NOT EXISTS idx_transfers_target
    ON transfer_rules(target_institution);

-- ============================================
-- Migration 002: Transfer History
-- ============================================

-- Create transfer_history table for tracking lookups
CREATE TABLE IF NOT EXISTS transfer_history (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    ip_hash TEXT,
    source_institution TEXT NOT NULL,
    target_institution TEXT NOT NULL,
    source_courses TEXT NOT NULL,  -- JSON array
    result_json TEXT NOT NULL,  -- JSON: TransferResult
    created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_transfer_history_user
    ON transfer_history(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_transfer_history_date
    ON transfer_history(created_at);

-- ============================================
-- Migration 003: Transfer Sources
-- ============================================

-- Create transfer_sources table for attribution
CREATE TABLE IF NOT EXISTS transfer_sources (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,  -- e.g., 'BC Transfer Guide'
    abbreviation TEXT,    -- e.g., 'BCTG'
    url TEXT NOT NULL,
    description TEXT,
    attribution_required INTEGER DEFAULT 1 CHECK(attribution_required IN (0, 1)),
    api_endpoint TEXT,
    api_key TEXT,  -- Encrypted
    last_synced TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Link rules to sources
CREATE TABLE IF NOT EXISTS transfer_rule_sources (
    rule_id TEXT NOT NULL,
    source_id TEXT NOT NULL,
    external_id TEXT,  -- ID in source system
    PRIMARY KEY (rule_id, source_id),
    FOREIGN KEY (rule_id) REFERENCES transfer_rules(id),
    FOREIGN KEY (source_id) REFERENCES transfer_sources(id)
);

-- ============================================
-- Migration 004: Popular Transfers
-- ============================================

-- Create popular_transfers table for caching common lookups
CREATE TABLE IF NOT EXISTS popular_transfers (
    id TEXT PRIMARY KEY,
    source_institution TEXT NOT NULL,
    target_institution TEXT NOT NULL,
    source_course TEXT NOT NULL,
    target_course TEXT NOT NULL,
    query_count INTEGER DEFAULT 0,
    last_queried TEXT,
    created_at TEXT NOT NULL,
    UNIQUE(source_institution, target_institution, source_course, target_course)
);

CREATE INDEX IF NOT EXISTS idx_popular_transfers_count
    ON popular_transfers(query_count DESC);

-- ============================================
-- Views
-- ============================================

-- View: Active transfer rules with parsed LHS
CREATE VIEW IF NOT EXISTS active_transfers AS
SELECT
    id,
    source_institution,
    target_institution,
    json_extract(lhs_json, '$') as lhs,
    json_extract(rhs_json, '$') as rhs,
    effective_start,
    effective_end,
    confidence,
    is_active
FROM transfer_rules
WHERE is_active = 1;

-- View: Transfer summary by institution pair
CREATE VIEW IF NOT EXISTS transfer_summary AS
SELECT
    source_institution,
    target_institution,
    COUNT(*) as rule_count,
    AVG(confidence) as avg_confidence
FROM transfer_rules
WHERE is_active = 1
GROUP BY source_institution, target_institution;

-- ============================================
-- Triggers
-- ============================================

CREATE TRIGGER IF NOT EXISTS transfers_updated_at
    AFTER UPDATE ON transfer_rules
BEGIN
    UPDATE transfer_rules SET updated_at = datetime('now') WHERE id = NEW.id;
END;

-- ============================================
-- Seed BC Transfer Guide source
-- ============================================

INSERT INTO transfer_sources (id, name, abbreviation, url, description, attribution_required, created_at, updated_at) VALUES
('bctg', 'BC Transfer Guide', 'BCTG', 'https://www.bctransferguide.ca', 'Official BC transfer credit guide', 1, datetime('now'), datetime('now'));
