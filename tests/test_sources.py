from scraper.sources import SOURCES
from scraper.sources.indeed import IndeedSource


def test_registry_contains_expected_sources_only():
    assert set(SOURCES) == {"jobbank", "indeed", "kijiji", "randstad"}


def test_indeed_source_is_registered():
    assert SOURCES["indeed"] is IndeedSource


def test_indeed_normalizes_job_type():
    assert IndeedSource._normalize_job_type("full_time") == "Full-time"
    assert IndeedSource._normalize_job_type("part-time") == "Part-time"


def test_indeed_splits_canadian_location():
    assert IndeedSource._split_location("Vancouver, British Columbia") == (
        "Vancouver",
        "BC",
    )
