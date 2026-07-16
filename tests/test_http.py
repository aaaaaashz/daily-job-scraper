import requests

from scraper.http import fetch


class FakeSession:
    def __init__(self, responses):
        self.responses = iter(responses)
        self.calls = 0

    def get(self, url, params=None, timeout=None):
        self.calls += 1
        response = next(self.responses)
        response.url = url
        return response


def response(status, retry_after=None):
    value = requests.Response()
    value.status_code = status
    if retry_after is not None:
        value.headers["Retry-After"] = retry_after
    value._content = b"ok"
    return value


def test_retryable_status_then_success(monkeypatch):
    sleeps = []
    monkeypatch.setattr("scraper.http.time.sleep", sleeps.append)
    session = FakeSession([response(503), response(200)])

    result = fetch(session, "https://example.com", retries=1, backoff=0)

    assert result.status_code == 200
    assert session.calls == 2
    assert len(sleeps) == 1


def test_retry_after_is_honored(monkeypatch):
    sleeps = []
    monkeypatch.setattr("scraper.http.time.sleep", sleeps.append)
    session = FakeSession([response(429, "3"), response(200)])

    fetch(session, "https://example.com", retries=1, backoff=0)

    assert sleeps == [3.0]


def test_non_retryable_http_error_raises(monkeypatch):
    monkeypatch.setattr("scraper.http.time.sleep", lambda _: None)
    session = FakeSession([response(403)])

    try:
        fetch(session, "https://example.com", retries=3)
    except requests.HTTPError as exc:
        assert exc.response.status_code == 403
    else:
        raise AssertionError("expected HTTPError")
