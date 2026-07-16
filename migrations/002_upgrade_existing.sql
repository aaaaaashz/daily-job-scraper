-- Upgrade the original schema without deleting existing jobs.
-- Run only when the database was created from the earlier 001_init.sql.

BEGIN;

CREATE TABLE IF NOT EXISTS job_posting_occupations (
    job_posting_id INT NOT NULL REFERENCES job_postings(id) ON DELETE CASCADE,
    occupation_id  INT NOT NULL REFERENCES occupations(id) ON DELETE CASCADE,
    first_seen_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (job_posting_id, occupation_id)
);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'job_postings' AND column_name = 'occupation_id'
    ) THEN
        INSERT INTO job_posting_occupations (job_posting_id, occupation_id)
        SELECT id, occupation_id
        FROM job_postings
        WHERE occupation_id IS NOT NULL
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

ALTER TABLE job_posting_sources
    ADD COLUMN IF NOT EXISTS source_key TEXT,
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS first_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now();

UPDATE job_posting_sources
SET source_key = COALESCE(NULLIF(external_id, ''), url)
WHERE source_key IS NULL;

ALTER TABLE job_posting_sources
    ALTER COLUMN source_key SET NOT NULL;

-- Keep one row if the old database already contains repeated source identities.
DELETE FROM job_posting_sources older
USING job_posting_sources newer
WHERE older.id < newer.id
  AND older.source = newer.source
  AND older.source_key = newer.source_key;

ALTER TABLE job_posting_sources
    DROP CONSTRAINT IF EXISTS job_posting_sources_job_posting_id_source_key;

CREATE UNIQUE INDEX IF NOT EXISTS uq_job_source_identity
    ON job_posting_sources (source, source_key);

ALTER TABLE job_postings
    DROP COLUMN IF EXISTS occupation_id;

ALTER TABLE scrape_runs
    ADD COLUMN IF NOT EXISTS enabled_sources TEXT[] NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS searches_attempted INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS searches_succeeded INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS searches_failed INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS jobs_discarded INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS source_links_new INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS source_links_deactivated INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS duration_ms INT;

CREATE TABLE IF NOT EXISTS scrape_run_searches (
    id                 SERIAL PRIMARY KEY,
    run_id             INT NOT NULL REFERENCES scrape_runs(id) ON DELETE CASCADE,
    source             TEXT NOT NULL,
    occupation_id      INT NOT NULL REFERENCES occupations(id),
    search_term        TEXT NOT NULL,
    started_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    finished_at        TIMESTAMPTZ,
    status             TEXT NOT NULL CHECK (status IN ('success', 'failed')),
    complete           BOOLEAN NOT NULL DEFAULT TRUE,
    pages_fetched      INT NOT NULL DEFAULT 0,
    listings_found     INT NOT NULL DEFAULT 0,
    listings_discarded INT NOT NULL DEFAULT 0,
    duration_ms        INT NOT NULL DEFAULT 0,
    note               TEXT,
    error_message      TEXT,
    UNIQUE (run_id, source, occupation_id, search_term)
);

CREATE INDEX IF NOT EXISTS idx_job_occupation_lookup
    ON job_posting_occupations (occupation_id, job_posting_id);
CREATE INDEX IF NOT EXISTS idx_active_jobs_employment_type
    ON job_postings (employment_type) WHERE is_active;
CREATE INDEX IF NOT EXISTS idx_source_stale_cleanup
    ON job_posting_sources (source, last_seen_at) WHERE is_active;
CREATE INDEX IF NOT EXISTS idx_scrape_searches_run
    ON scrape_run_searches (run_id, source, status);

COMMIT;
