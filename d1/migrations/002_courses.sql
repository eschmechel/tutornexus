-- Tutor Nexus D1 Database Migrations
-- Database: tn-courses

-- ============================================
-- Migration 001: Courses Schema
-- ============================================

-- Create institutions table
CREATE TABLE IF NOT EXISTS institutions (
    id TEXT PRIMARY KEY,  -- 'sfu', 'langara', etc.
    name TEXT NOT NULL,
    display_name TEXT NOT NULL,
    abbreviation TEXT NOT NULL,
    website TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Create courses table
CREATE TABLE IF NOT EXISTS courses (
    id TEXT PRIMARY KEY,
    institution TEXT NOT NULL,
    code TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    credits INTEGER DEFAULT 3,
    prerequisites TEXT,  -- JSON array of course refs
    corequisites TEXT,  -- JSON array of course refs
    antirequisites TEXT,  -- JSON array of course refs
    equivalent_to TEXT,  -- JSON array of course refs
    conditions TEXT,
    valid_from TEXT,  -- Term code, e.g., '2024F'
    valid_until TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (institution) REFERENCES institutions(id),
    UNIQUE(institution, code)
);

-- Create indexes for course lookups
CREATE INDEX IF NOT EXISTS idx_courses_institution_code
    ON courses(institution, code);
CREATE INDEX IF NOT EXISTS idx_courses_title
    ON courses(title);
CREATE INDEX IF NOT EXISTS idx_courses_credits
    ON courses(credits);

-- Create course_tags table for categorization
CREATE TABLE IF NOT EXISTS course_tags (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    tag TEXT NOT NULL,
    FOREIGN KEY (course_id) REFERENCES courses(id),
    UNIQUE(course_id, tag)
);

CREATE INDEX IF NOT EXISTS idx_course_tags_tag
    ON course_tags(tag);

-- ============================================
-- Migration 002: Outlines
-- ============================================

-- Create outlines table
CREATE TABLE IF NOT EXISTS outlines (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL UNIQUE,
    learning_outcomes TEXT NOT NULL,  -- JSON array
    grading_scheme TEXT NOT NULL,  -- JSON array of {component, weight}
    topics TEXT NOT NULL,  -- JSON array
    required_texts TEXT,  -- JSON array
    recommended_texts TEXT,  -- JSON array
    policies TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (course_id) REFERENCES courses(id)
);

-- ============================================
-- Migration 003: Instructors
-- ============================================

-- Create instructors table
CREATE TABLE IF NOT EXISTS instructors (
    id TEXT PRIMARY KEY,
    institution TEXT NOT NULL,
    name TEXT NOT NULL,
    email TEXT,
    office TEXT,
    website TEXT,
    rating REAL,  -- From student reviews
    review_count INTEGER DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (institution) REFERENCES institutions(id)
);

-- Create course_instructors linking table
CREATE TABLE IF NOT EXISTS course_instructors (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    instructor_id TEXT NOT NULL,
    term TEXT NOT NULL,
    section TEXT NOT NULL,
    FOREIGN KEY (course_id) REFERENCES courses(id),
    FOREIGN KEY (instructor_id) REFERENCES instructors(id),
    UNIQUE(course_id, term, section)
);

-- ============================================
-- Migration 004: Sections and Schedules
-- ============================================

-- Create sections table
CREATE TABLE IF NOT EXISTS sections (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    term TEXT NOT NULL,  -- e.g., '2024F'
    section TEXT NOT NULL,  -- e.g., 'D100'
    type TEXT DEFAULT 'lecture' CHECK(type IN ('lecture', 'lab', 'tutorial', 'seminar')),
    instructor_id TEXT,
    capacity INTEGER,
    enrolled INTEGER DEFAULT 0,
    location TEXT,
    schedule TEXT NOT NULL,  -- JSON array of {day, start, end, location}
    notes TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (course_id) REFERENCES courses(id),
    FOREIGN KEY (instructor_id) REFERENCES instructors(id),
    UNIQUE(course_id, term, section)
);

CREATE INDEX IF NOT EXISTS idx_sections_term
    ON sections(term);
CREATE INDEX IF NOT EXISTS idx_sections_instructor
    ON sections(instructor_id);

-- ============================================
-- Migration 005: Course Materials
-- ============================================

-- Create materials table
CREATE TABLE IF NOT EXISTS materials (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    type TEXT NOT NULL CHECK(type IN ('exam', 'homework', 'notes', 'slides', 'other')),
    title TEXT NOT NULL,
    description TEXT,
    url TEXT NOT NULL,
    file_size INTEGER,
    mime_type TEXT,
    uploaded_at TEXT,
    term TEXT,
    FOREIGN KEY (course_id) REFERENCES courses(id)
);

CREATE INDEX IF NOT EXISTS idx_materials_course
    ON materials(course_id, type);
CREATE INDEX IF NOT EXISTS idx_materials_type
    ON materials(type);

-- ============================================
-- Migration 006: Grade Distributions
-- ============================================

-- Create grade_distributions table
CREATE TABLE IF NOT EXISTS grade_distributions (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    term TEXT NOT NULL,
    section TEXT NOT NULL,
    a_plus INTEGER DEFAULT 0,
    a INTEGER DEFAULT 0,
    a_minus INTEGER DEFAULT 0,
    b_plus INTEGER DEFAULT 0,
    b INTEGER DEFAULT 0,
    b_minus INTEGER DEFAULT 0,
    c_plus INTEGER DEFAULT 0,
    c INTEGER DEFAULT 0,
    c_minus INTEGER DEFAULT 0,
    d_plus INTEGER DEFAULT 0,
    d INTEGER DEFAULT 0,
    d_minus INTEGER DEFAULT 0,
    f INTEGER DEFAULT 0,
    average REAL,
    median REAL,
    created_at TEXT NOT NULL,
    FOREIGN KEY (course_id) REFERENCES courses(id),
    UNIQUE(course_id, term, section)
);

CREATE INDEX IF NOT EXISTS idx_grades_course
    ON grade_distributions(course_id);

-- ============================================
-- Migration 007: Raw Fetch Metadata
-- ============================================

-- Create raw_fetches table for caching
CREATE TABLE IF NOT EXISTS raw_fetches (
    id TEXT PRIMARY KEY,
    institution TEXT NOT NULL,
    url TEXT NOT NULL,
    content_type TEXT,
    content_hash TEXT NOT NULL,
    fetched_at TEXT NOT NULL,
    expires_at TEXT,
    raw_content BLOB,
    FOREIGN KEY (institution) REFERENCES institutions(id),
    UNIQUE(url)
);

CREATE INDEX IF NOT EXISTS idx_raw_fetches_institution
    ON raw_fetches(institution);
CREATE INDEX IF NOT EXISTS idx_raw_fetches_hash
    ON raw_fetches(content_hash);

-- ============================================
-- Views
-- ============================================

-- View: Course with prerequisites resolved
CREATE VIEW IF NOT EXISTS courses_with_prereqs AS
SELECT
    c.id,
    c.institution,
    c.code,
    c.title,
    c.credits,
    c.description,
    json_extract(c.prerequisites, '$') as prereq_list,
    i.name as instructor_name,
    (SELECT COUNT(*) FROM sections s WHERE s.course_id = c.id AND s.term = '2024F') as offering_count
FROM courses c
LEFT JOIN course_instructors ci ON c.id = ci.course_id
LEFT JOIN instructors i ON ci.instructor_id = i.id
WHERE ci.term = '2024F' OR i.id IS NULL;

-- ============================================
-- Triggers
-- ============================================

CREATE TRIGGER IF NOT EXISTS courses_updated_at
    AFTER UPDATE ON courses
BEGIN
    UPDATE courses SET updated_at = datetime('now') WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS outlines_updated_at
    AFTER UPDATE ON outlines
BEGIN
    UPDATE outlines SET updated_at = datetime('now') WHERE id = NEW.id;
END;

-- Seed institutions
INSERT INTO institutions (id, name, display_name, abbreviation, website, created_at, updated_at) VALUES
('sfu', 'Simon Fraser University', 'Simon Fraser University', 'SFU', 'https://www.sfu.ca', datetime('now'), datetime('now')),
('langara', 'Langara College', 'Langara College', 'Langara', 'https://langara.ca', datetime('now'), datetime('now')),
('ubc', 'University of British Columbia', 'University of British Columbia', 'UBC', 'https://ubc.ca', datetime('now'), datetime('now')),
('douglas', 'Douglas College', 'Douglas College', 'Douglas', 'https://douglascollege.ca', datetime('now'), datetime('now')),
('tru', 'Thompson Rivers University', 'Thompson Rivers University', 'TRU', 'https://tru.ca', datetime('now'), datetime('now'));
