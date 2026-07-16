import pytest

from scraper.models import JobListing
from scraper.validation import InvalidListing, validate_listing


def valid_listing(**overrides):
    values = {
        "title": "  Industrial   Electrician  ",
        "employer": " ACME Ltd. ",
        "city": " Vancouver ",
        "province": "British Columbia",
        "employment_type": " Full-time ",
        "url": "https://example.com/jobs/1?utm_source=test",
        "source": "jobbank",
        "external_id": " 123 ",
    }
    values.update(overrides)
    return JobListing(**values)


def test_validation_cleans_fields():
    result = validate_listing(valid_listing(), "jobbank")
    assert result.title == "Industrial Electrician"
    assert result.employer == "ACME Ltd."
    assert result.city == "Vancouver"
    assert result.province == "BC"
    assert result.url == "https://example.com/jobs/1"
    assert result.external_id == "123"


def test_invalid_url_rejected():
    with pytest.raises(InvalidListing):
        validate_listing(valid_listing(url="not-a-url"), "jobbank")


def test_source_mismatch_rejected():
    with pytest.raises(InvalidListing):
        validate_listing(valid_listing(source="kijiji"), "jobbank")


def test_unknown_province_rejected():
    with pytest.raises(InvalidListing):
        validate_listing(valid_listing(province="New York"), "jobbank")
