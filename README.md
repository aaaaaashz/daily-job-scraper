# Gigsup Daily Job Scraping Agent

A scheduled Python service that collects focused skilled-trades jobs into PostgreSQL once per day. Matching and filtering read from the database instead of calling job boards during a user request.

## Requirements covered

- Reads only occupations where `occupations.is_focused = TRUE`.
- Searches every configured term for every focused occupation.
- Supports government and skilled-trades sources.
- Merges the same role across sources.
- Stores title, employer, city, province, employment type, and every source URL.
- Filters results to the configured target location.
- Records run totals and one audit row per source, occupation, and search term.
- Prevents overlapping scheduled runs with a PostgreSQL advisory lock.
- Marks stale source links inactive without deleting history.

## Sources

| Source | Type | Coverage behavior |
|---|---|---|
| Job Bank Canada | Government | Paginated until exhausted or the configured page cap |
| Kijiji Jobs | Marketplace | Paginated until exhausted or the configured page cap |
| Randstad Canada | Staffing and skilled trades | Public page exposes one result batch, so a longer stale grace period is used |
| Indeed | Major commercial job board | Included through `python-jobspy` |

## Setup

```bash
python -m venv .venv
```

Windows:

```bash
.venv\Scripts\activate
python -m pip install -r requirements-dev.txt
copy .env.example .env
```

macOS or Linux:

```bash
. .venv/bin/activate
python -m pip install -r requirements-dev.txt
cp .env.example .env
```

Set `DATABASE_URL` in `.env`, then initialize a fresh database:

```bash
psql "$DATABASE_URL" -f migrations/001_init.sql
```

For a database created with the earlier schema:

```bash
psql "$DATABASE_URL" -f migrations/002_upgrade_existing.sql
```

Validate the environment before the first run:

```bash
python -m scraper.main validate-config
```

## Commands

```bash
python -m scraper.main run
python -m scraper.main status --limit 10
python -m scraper.main test-source indeed electrician --location "Vancouver, BC"
python -m scraper.main validate-config
```

Exit codes for `run`:

- `0`: success
- `1`: fatal run failure
- `2`: partial run with one or more failed searches

## Scheduling

Windows Task Scheduler action:

```text
C:\path\to\project\run_daily_scrape.bat
```

Linux cron at 5:00 AM:

```cron
0 5 * * * /path/to/project/run_daily_scrape.sh
```

The wrapper scripts change into the repository directory before starting Python. This keeps `.env` and log paths consistent.

## Data model

`job_postings` stores one canonical role.

`job_posting_sources` stores each board listing, URL, external ID, source-level activity, and last-seen time.

`job_posting_occupations` links one merged job to one or more focused occupations.

`scrape_runs` stores run totals.

`scrape_run_searches` stores one row for every source, occupation, and term. It includes duration, pages fetched, completeness, discarded listings, and error text.

## Matching query

```sql
SELECT
    jp.id,
    jp.title,
    jp.employer,
    jp.city,
    jp.province,
    jp.employment_type,
    jsonb_agg(
        jsonb_build_object(
            'source', jps.source,
            'url', jps.url
        )
        ORDER BY jps.source
    ) AS sources
FROM job_postings jp
JOIN job_posting_occupations jpo
  ON jpo.job_posting_id = jp.id
JOIN job_posting_sources jps
  ON jps.job_posting_id = jp.id
 AND jps.is_active
WHERE jp.is_active
  AND jpo.occupation_id = $1
  AND ($2::text IS NULL OR jp.province = $2)
  AND ($3::text IS NULL OR jp.city ILIKE $3)
  AND ($4::text IS NULL OR jp.employment_type = $4)
GROUP BY jp.id
ORDER BY jp.last_seen_at DESC;
```

## Deduplication

The database checks exact source identity first using `source + external_id`, or `source + canonical URL` when no external ID exists.

New source listings are then merged across boards using normalized:

```text
title + employer + city + province
```

Company suffixes, punctuation, accents, casing, and repeated whitespace are normalized. Listings missing an employer or city use source identity instead of unsafe title-only merging.

## Reliability behavior

- HTTP timeout on every request.
- Exponential retry delay with jitter.
- `Retry-After` support for rate limits.
- Per-search database transaction.
- One failed search does not erase successful searches.
- Overlapping daily runs are blocked.
- Complete sources use `STALE_AFTER_DAYS`.
- Capped sources use `INCOMPLETE_SOURCE_STALE_AFTER_DAYS`.
- Sources with failed searches are skipped during stale cleanup for that run.

## Tests and linting

```bash
ruff check .
python -m pytest -q
```

Parser tests use saved HTML fixtures and run without internet access. GitHub Actions runs linting and tests on Python 3.11 and 3.12.
