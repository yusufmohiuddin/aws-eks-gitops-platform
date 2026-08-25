# Platform Reference Service

The Platform Reference Service is an instrumented workload used to validate
delivery and operational capabilities provided by the AWS EKS GitOps Platform.

It is intentionally small. Its purpose is to exercise build, security,
deployment, scaling, observability, failure-recovery, and rollback workflows
without introducing unrelated business-domain complexity.

## Service contract

| Endpoint | Purpose |
|---|---|
| `GET /` | Service identity |
| `GET /version` | Build, revision, and environment metadata |
| `GET /health/live` | Process liveness |
| `GET /health/ready` | Traffic readiness |
| `GET /metrics` | Prometheus metrics |

## Operational requirements

- Configuration is supplied through environment variables.
- Logs are emitted as structured JSON.
- Build and release identity is visible at runtime.
- Liveness does not depend on external services.
- Readiness reflects whether the instance can accept traffic.
- Shutdown removes the instance from service before process termination.
- The container runs as a non-root user with a read-only root filesystem.

## Local development

```bash
uv sync --locked
uv run uvicorn platform_reference_service.main:app --reload --port 8080
```

Run the complete application quality gate:

```bash
uv run ruff format --check .
uv run ruff check .
uv run mypy src
uv run pytest --cov=platform_reference_service --cov-fail-under=90
```

## Container

```bash
docker build -t platform-reference-service:local .
docker run --rm -p 8080:8080 platform-reference-service:local
```
