from scraper.location import matches_target_location
from scraper.models import JobListing


def listing(city="Vancouver", province="BC"):
    return JobListing(
        title="Electrician",
        employer="ACME",
        city=city,
        province=province,
        employment_type="Full-time",
        url="https://example.com/jobs/1",
        source="test",
    )


def test_canada_matches_everywhere():
    assert matches_target_location(listing(), "Canada")


def test_province_name_and_code_match():
    assert matches_target_location(listing(), "British Columbia")
    assert matches_target_location(listing(), "BC")


def test_city_matches_case_insensitively():
    assert matches_target_location(listing(), "vancouver")


def test_city_and_province_match():
    assert matches_target_location(listing(), "Vancouver, BC")
    assert not matches_target_location(listing(), "Vancouver, ON")


def test_other_city_is_rejected():
    assert not matches_target_location(listing(), "Victoria")
