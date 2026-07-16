# Submission guide

## Use this version

Submit the cleaned repository folder or the provided ZIP. Do not add the original `.env`, `.git`, caches, or log files.

## Database choice

For a fresh review database, run:

```bash
psql "$DATABASE_URL" -f migrations/001_init.sql
```

For the database created from the original migration, run:

```bash
psql "$DATABASE_URL" -f migrations/002_upgrade_existing.sql
```

Do not run both migrations on a fresh database.

## Before submitting

```bash
python -m pip install -r requirements-dev.txt
ruff check .
python -m pytest -q
python -m scraper.main validate-config
python -m scraper.main test-source indeed electrician --location Canada --limit 5
```

Then run one database-backed scrape:

```bash
python -m scraper.main run
python -m scraper.main status --limit 3
```

## Files to replace

Replace the original contents of:

- `scraper/config.py`
- `scraper/db.py`
- `scraper/dedup.py`
- `scraper/http.py`
- `scraper/main.py`
- `scraper/models.py`
- `scraper/runner.py`
- every file in `scraper/sources/`
- `migrations/001_init.sql`
- `README.md`
- `.env.example`
- `.gitignore`
- `requirements.txt`
- `requirements-dev.txt`
- `run_daily_scrape.bat`
- existing tests

## Files to add

- `scraper/location.py`
- `scraper/validation.py`
- `migrations/002_upgrade_existing.sql`
- `pyproject.toml`
- `run_daily_scrape.sh`
- `.github/workflows/ci.yml`
- `CHANGES.md`
- added tests

## Files to delete from any submitted archive

- `.env`
- `.git/`
- `.pytest_cache/`
- `.ruff_cache/`
- `__pycache__/`
- `*.pyc`
- `scrape.log`

## Demo flow for the technical round

1. Show `occupations` controls the scrape scope.
2. Run `test-source` for one occupation.
3. Show `scrape_run_searches` records source-level success, timing, page count, and completeness.
4. Show one job linked to multiple source URLs.
5. Show the matching query joins through `job_posting_occupations`.
6. Explain why failed sources are excluded from stale cleanup.
7. Explain why capped sources use a longer stale window.
8. Explain the advisory lock protecting scheduled runs.
