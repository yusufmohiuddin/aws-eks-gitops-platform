from fastapi.testclient import TestClient

from platform_reference_service.config import get_settings
from platform_reference_service.main import app


def test_service_identity() -> None:
    with TestClient(app) as client:
        response = client.get("/")

    assert response.status_code == 200
    assert response.json() == {
        "service": "platform-reference-service",
        "environment": "development",
        "status": "running",
    }


def test_version_information(monkeypatch) -> None:
    monkeypatch.setenv("SERVICE_VERSION", "1.2.3")
    monkeypatch.setenv("GIT_SHA", "abc123")
    monkeypatch.setenv("ENVIRONMENT", "staging")
    get_settings.cache_clear()

    try:
        with TestClient(app) as client:
            response = client.get("/version")
    finally:
        get_settings.cache_clear()

    assert response.status_code == 200
    assert response.json() == {
        "service": "platform-reference-service",
        "version": "1.2.3",
        "git_sha": "abc123",
        "environment": "staging",
    }


def test_liveness() -> None:
    with TestClient(app) as client:
        response = client.get("/health/live")

    assert response.status_code == 200
    assert response.json() == {"status": "alive"}


def test_readiness_during_lifespan() -> None:
    with TestClient(app) as client:
        response = client.get("/health/ready")

    assert response.status_code == 200
    assert response.json() == {"status": "ready"}


def test_metrics_are_exposed() -> None:
    with TestClient(app) as client:
        client.get("/health/live")
        response = client.get("/metrics")

    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/plain")
    assert "platform_reference_http_requests_total" in response.text
    assert 'route="/health/live"' in response.text
