-- Fresh database schema.
-- Usage: psql "$DATABASE_URL" -f migrations/001_init.sql

CREATE TABLE IF NOT EXISTS occupations (
    id            SERIAL PRIMARY KEY,
    name          TEXT NOT NULL UNIQUE,
    noc_code      TEXT,
    search_terms  TEXT[] NOT NULL DEFAULT '{}',
    is_focused    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One canonical job row, merged across boards when title, employer, and location match.
CREATE TABLE IF NOT EXISTS job_postings (
    id              SERIAL PRIMARY KEY,
    fingerprint     TEXT NOT NULL UNIQUE,
    title           TEXT NOT NULL,
    employer        TEXT,
    city            TEXT,
    province        TEXT CHECK (province IS NULL OR province ~ '^[A-Z]{2}$'),
    employment_type TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    first_seen_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- A merged job may match more than one focused occupation.
CREATE TABLE IF NOT EXISTS job_posting_occupations (
    job_posting_id INT NOT NULL REFERENCES job_postings(id) ON DELETE CASCADE,
    occupation_id  INT NOT NULL REFERENCES occupations(id) ON DELETE CASCADE,
    first_seen_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (job_posting_id, occupation_id)
);

-- Each board listing keeps its own URL and lifecycle.
CREATE TABLE IF NOT EXISTS job_posting_sources (
    id              SERIAL PRIMARY KEY,
    job_posting_id  INT NOT NULL REFERENCES job_postings(id) ON DELETE CASCADE,
    source          TEXT NOT NULL,
    source_key      TEXT NOT NULL,
    url             TEXT NOT NULL,
    external_id     TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    first_seen_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (source, source_key)
);

CREATE INDEX IF NOT EXISTS idx_job_occupation_lookup
    ON job_posting_occupations (occupation_id, job_posting_id);
CREATE INDEX IF NOT EXISTS idx_active_jobs_province
    ON job_postings (province) WHERE is_active;
CREATE INDEX IF NOT EXISTS idx_active_jobs_city
    ON job_postings (city) WHERE is_active;
CREATE INDEX IF NOT EXISTS idx_active_jobs_employment_type
    ON job_postings (employment_type) WHERE is_active;
CREATE INDEX IF NOT EXISTS idx_source_stale_cleanup
    ON job_posting_sources (source, last_seen_at) WHERE is_active;

CREATE TABLE IF NOT EXISTS scrape_runs (
    id                       SERIAL PRIMARY KEY,
    started_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    finished_at              TIMESTAMPTZ,
    status                   TEXT NOT NULL DEFAULT 'running'
                             CHECK (status IN ('running', 'success', 'partial', 'failed')),
    enabled_sources          TEXT[] NOT NULL DEFAULT '{}',
    occupations_scraped      INT NOT NULL DEFAULT 0,
    searches_attempted       INT NOT NULL DEFAULT 0,
    searches_succeeded       INT NOT NULL DEFAULT 0,
    searches_failed          INT NOT NULL DEFAULT 0,
    jobs_found               INT NOT NULL DEFAULT 0,
    jobs_discarded           INT NOT NULL DEFAULT 0,
    jobs_new                 INT NOT NULL DEFAULT 0,
    jobs_updated             INT NOT NULL DEFAULT 0,
    source_links_new         INT NOT NULL DEFAULT 0,
    source_links_deactivated INT NOT NULL DEFAULT 0,
    jobs_deactivated         INT NOT NULL DEFAULT 0,
    duration_ms              INT,
    errors                   JSONB NOT NULL DEFAULT '[]'::jsonb
);

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

CREATE INDEX IF NOT EXISTS idx_scrape_searches_run
    ON scrape_run_searches (run_id, source, status);

INSERT INTO occupations (name, noc_code, search_terms) VALUES
    ('Electrician', '72200', '{"electrician apprentice"}'),
    ('Plumber', '72300', '{"plumber apprentice"}'),
    ('Welder', '72106', '{}'),
    ('Carpenter', '72310', '{}'),
    ('HVAC Technician', '72402', '{"refrigeration mechanic"}'),
    ('Heavy Equipment Operator', '73400', '{}')
ON CONFLICT (name) DO NOTHING;
