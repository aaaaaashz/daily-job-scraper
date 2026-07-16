# File-by-file change list

## Changed

### `scraper/runner.py`

- Added per-search transactions and timing.
- Added in-run duplicate suppression across overlapping search terms.
- Added listing validation before database writes.
- Added source-level health tracking.
- Added short and long stale policies for complete and capped sources.
- Added structured summary logging.
- Added cleanup for open HTTP sessions.
- Added partial-run exit behavior through `RunOutcome`.

### `scraper/db.py`

- Added a PostgreSQL advisory lock to prevent overlapping scheduled runs.
- Changed upsert order to exact source identity first, then cross-source fingerprint matching.
- Added many-to-many occupation links.
- Added detailed search audit inserts.
- Added source-link deactivation and parent-job activity recalculation.
- Added typed upsert results.

### `scraper/dedup.py`

- Split company normalization from general text normalization.
- Added Unicode and accent normalization.
- Added canonical URL handling.
- Added stable source identity.
- Added province to the cross-source fingerprint.
- Prevented unsafe cross-source merging when employer or city is missing.
- Replaced SHA-1 with SHA-256 for fingerprints.

### `scraper/http.py`

- Added exponential retry delay.
- Added jitter.
- Added `Retry-After` support.
- Moved timeout and retry values into environment settings.
- Preserved immediate handling of non-retryable HTTP failures.

### `scraper/config.py`

- Added numeric environment validation.
- Added HTTP timeout, retry, and backoff settings.
- Added separate stale grace for incomplete sources.
- Added Indeed to the default source list and normal project dependencies.
- Added `validate_runtime_config()`.

### `scraper/models.py`

- Added `SearchResult` with page count and completeness.
- Added `RunStats`, `RunOutcome`, and `UpsertResult`.
- Made listing and occupation models immutable and slot-based.
- Deduplicated repeated occupation search terms.

### `scraper/main.py`

- Added `validate-config`.
- Added `--location` and `--limit` to `test-source`.
- Added `--limit` to `status`.
- Added explicit exit codes for success, fatal failure, and partial runs.
- Improved console and rotating-file logging setup.

### Source adapters

- Changed `search()` to return `SearchResult`.
- Added session cleanup.
- Added target-location filtering for Kijiji and Randstad.
- Reported page-cap and source-cap completeness.
- Fixed Kijiji listings with missing external IDs.
- Added clearer malformed-page errors.
- Added a dedicated `IndeedSource` adapter backed by `python-jobspy`.

### `migrations/001_init.sql`

- Replaced one occupation column with `job_posting_occupations`.
- Added source-level identity and activity fields.
- Added detailed run-search audit table.
- Added matching, filtering, and cleanup indexes.
- Added run status and count fields.

### `README.md`

- Added setup, scheduling, exit codes, architecture, matching query, dedup behavior, and reliability behavior.

### `.env.example`

- Added all runtime settings.
- Removed optional adapters from defaults.
- Added supported target-location formats.

### `.gitignore`

- Added secret, cache, log, coverage, and archive exclusions.

### `run_daily_scrape.bat`

- Added repository-directory handling and exit-code forwarding.

## Added

- `scraper/location.py`
- `scraper/validation.py`
- `migrations/002_upgrade_existing.sql`
- `pyproject.toml`
- `run_daily_scrape.sh`
- `.github/workflows/ci.yml`
- Tests for location filtering, validation, URL identity, retry behavior, and model behavior.

## Deleted from the submitted package

- `.env`
- `.git/`
- `.pytest_cache/`
- every `__pycache__/`
- every `.pyc` file

## High-priority interview talking points

1. Exact source identity prevents the same board listing from drifting when its title changes.
2. Cross-source fingerprints merge duplicate roles without merging unrelated title-only listings.
3. The many-to-many occupation table prevents a merged job from being trapped under the first matching occupation.
4. Per-search audit rows show which source, occupation, and term failed.
5. Source-specific stale cleanup avoids mass deactivation during an outage.
6. The advisory lock prevents two scheduled runs from updating the same records at once.

## Indeed source update

- Added a dedicated `scraper/sources/indeed.py` adapter.
- Moved `python-jobspy` into `requirements.txt`.
- Enabled Indeed by default.
- Limited the source registry to the four intended job boards.
