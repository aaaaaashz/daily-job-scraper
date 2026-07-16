import pytest

from scraper.sources.kijiji import KijijiSource


@pytest.fixture
def source():
    return KijijiSource()


def test_parses_listing_with_full_address(source, fixture):
    listings = source._parse_next_data(fixture("kijiji_search.html"))
    by_id = {item.external_id: item for item in listings}
    assert len(listings) == 2

    full = by_id["1737075154"]
    assert full.title == "Construction Electrician"
    assert full.employer == "MDG Electric Inc."
    assert full.city == "Navin"
    assert full.province == "MB"
    assert full.employment_type == "Full-time"
    assert full.url.endswith("/1737075154")


def test_province_falls_back_to_region_slug(source, fixture):
    listings = source._parse_next_data(fixture("kijiji_search.html"))
    bare = {item.external_id: item for item in listings}["1740005053"]
    # no address in the listing, but the URL says /calgary/
    assert bare.province == "AB"
    assert bare.city == "Calgary"
    assert bare.employer is None
    assert "?" not in bare.url  # tracking params stripped


def test_missing_next_data_raises(source):
    with pytest.raises(RuntimeError):
        source._parse_next_data("<html><body>redesigned page</body></html>")
