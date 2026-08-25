from platform_reference_service.config import Settings


def test_default_settings() -> None:
    settings = Settings()

    assert settings.service_name == "platform-reference-service"
    assert settings.service_version == "0.1.0"
    assert settings.git_sha == "local"
    assert settings.environment == "development"
    assert settings.log_level == "INFO"


def test_settings_from_environment(monkeypatch) -> None:
    monkeypatch.setenv("SERVICE_NAME", "verification-service")
    monkeypatch.setenv("SERVICE_VERSION", "1.2.3")
    monkeypatch.setenv("GIT_SHA", "abc123")
    monkeypatch.setenv("ENVIRONMENT", "staging")
    monkeypatch.setenv("LOG_LEVEL", "WARNING")

    settings = Settings()

    assert settings.service_name == "verification-service"
    assert settings.service_version == "1.2.3"
    assert settings.git_sha == "abc123"
    assert settings.environment == "staging"
    assert settings.log_level == "WARNING"
