from scraper.dedup import (
    canonicalize_url,
    fingerprint,
    listing_source_key,
    normalize_province,
)


def test_same_job_same_fingerprint():
    assert fingerprint("Welder", "ACME Inc.", "Toronto", "ON") == fingerprint(
        "welder", "acme incorporated", "toronto", "Ontario"
    )


def test_company_suffixes_ignored():
    assert fingerprint("Welder", "ACME Ltd.", "Toronto", "ON") == fingerprint(
        "Welder", "ACME Limited", "Toronto", "ON"
    )


def test_punctuation_and_accents_ignored():
    assert fingerprint(
        "Journeyman/Woman Electrician", "Énergie R&B Ltée", "Québec", "QC"
    ) == fingerprint(
        "journeyman woman electrician", "Energie R B", "Quebec", "Quebec"
    )


def test_different_province_changes_fingerprint():
    assert fingerprint("Welder", "ACME", "Springfield", "ON") != fingerprint(
        "Welder", "ACME", "Springfield", "NS"
    )


def test_missing_employer_uses_source_fallback():
    first = fingerprint("Welder", None, "Toronto", "ON", fallback_key="kijiji:1")
    second = fingerprint("Welder", None, "Toronto", "ON", fallback_key="kijiji:2")
    assert first != second


def test_url_canonicalization_removes_tracking():
    assert canonicalize_url(
        "HTTPS://Example.COM/jobs/1?utm_source=x&job=2#details"
    ) == "https://example.com/jobs/1?job=2"


def test_source_key_prefers_external_id():
    assert listing_source_key("jobbank", " 123 ", "https://example.com/ignored") == "123"


def test_source_key_falls_back_to_canonical_url():
    assert listing_source_key(
        "kijiji", None, "https://EXAMPLE.com/jobs/1?utm_campaign=test"
    ) == "https://example.com/jobs/1"


def test_normalize_province():
    assert normalize_province("Ontario") == "ON"
    assert normalize_province("bc") == "BC"
    assert normalize_province("Québec") == "QC"
    assert normalize_province("") is None
    assert normalize_province(None) is None
    assert normalize_province("New York") is None
