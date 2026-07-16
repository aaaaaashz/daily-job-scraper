import pytest

from scraper.sources.jobbank import JobBankSource


@pytest.fixture
def source():
    return JobBankSource()


def test_parses_listings(source, fixture):
    listings = source._parse_results(fixture("jobbank_results.html"))
    assert len(listings) == 2

    first = listings[0]
    assert first.title == "marine electrician"
    assert first.employer == "Revolution Yacht Experience Ltd"
    assert first.city == "Vancouver"
    assert first.province == "BC"
    expected_url = "https://www.jobbank.gc.ca/jobsearch/jobposting/49860469"
    assert first.url == expected_url  # jsessionid dropped
    assert first.external_id == "49860469"
    assert first.source == "jobbank"


def test_parses_city_comma_province_name(source, fixture):
    listings = source._parse_results(fixture("jobbank_results.html"))
    assert listings[1].city == "Windsor"
    assert listings[1].province == "ON"


def test_empty_results_page_returns_nothing(source, fixture):
    assert source._parse_results(fixture("jobbank_empty.html")) == []


def test_unrecognizable_page_raises(source):
    with pytest.raises(RuntimeError):
        source._parse_results("<html><body><p>totally different site</p></body></html>")


def test_parse_location_variants(source):
    assert source._parse_location("Location: Vancouver (BC)") == ("Vancouver", "BC")
    assert source._parse_location("Windsor, Ontario") == ("Windsor", "ON")
    assert source._parse_location("Fort St. John, BC") == ("Fort St. John", "BC")
    assert source._parse_location("") == (None, None)
