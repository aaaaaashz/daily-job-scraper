import pytest

from scraper.sources.randstad import RandstadSource


@pytest.fixture
def source():
    return RandstadSource()


def test_parses_canadian_job(source, fixture):
    listings = source._parse_embedded_jobs(fixture("randstad_search.html"))
    assert len(listings) == 1  # the US posting is filtered out

    job = listings[0]
    assert job.title == "Industrial Electrician"
    assert job.employer == "Randstad Canada"
    assert job.city == "Paris"
    assert job.province == "ON"
    assert job.employment_type == "Permanent"
    assert job.url == "https://www.randstad.ca/jobs/industrial-electrician_paris_46875574/"
    assert job.external_id == "46875574"


def test_us_postings_filtered(source, fixture):
    listings = source._parse_embedded_jobs(fixture("randstad_search.html"))
    assert all(item.province for item in listings)


def test_no_results_page_returns_empty(source):
    assert source._parse_embedded_jobs("<html><body>0 jobs found</body></html>") == []


def test_job_links_without_json_raises(source, fixture):
    # job links present but no embedded JSON = layout changed, should be loud
    with pytest.raises(RuntimeError):
        source._parse_embedded_jobs(fixture("randstad_broken.html"))
