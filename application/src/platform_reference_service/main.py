import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Annotated

from fastapi import Depends, FastAPI, Request, Response, status
from prometheus_client import CONTENT_TYPE_LATEST, Info, generate_latest

from platform_reference_service.config import Settings, get_settings
from platform_reference_service.logging import configure_logging
from platform_reference_service.metrics import MetricsMiddleware
from platform_reference_service.models import HealthStatus, ServiceIdentity, VersionInformation

logger = logging.getLogger(__name__)
SettingsDependency = Annotated[Settings, Depends(get_settings)]
BUILD_INFO = Info("platform_reference_build", "Build and release identity for the service.")


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    configure_logging(settings.log_level)
    BUILD_INFO.info(
        {
            "service": settings.service_name,
            "version": settings.service_version,
            "git_sha": settings.git_sha,
            "environment": settings.environment,
        }
    )
    app.state.ready = True
    logger.info("service_started")

    try:
        yield
    finally:
        app.state.ready = False
        logger.info("service_stopped")


app = FastAPI(
    title="Platform Reference Service",
    description="Instrumented validation workload for the AWS EKS GitOps Platform",
    version="0.1.0",
    lifespan=lifespan,
)
app.add_middleware(MetricsMiddleware)


@app.get("/", response_model=ServiceIdentity)
def service_identity(settings: SettingsDependency) -> ServiceIdentity:
    return ServiceIdentity(
        service=settings.service_name,
        environment=settings.environment,
    )


@app.get("/version", response_model=VersionInformation)
def version_information(settings: SettingsDependency) -> VersionInformation:
    return VersionInformation(
        service=settings.service_name,
        version=settings.service_version,
        git_sha=settings.git_sha,
        environment=settings.environment,
    )


@app.get("/health/live", response_model=HealthStatus)
def liveness() -> HealthStatus:
    return HealthStatus(status="alive")


@app.get(
    "/health/ready",
    response_model=HealthStatus,
    responses={status.HTTP_503_SERVICE_UNAVAILABLE: {"model": HealthStatus}},
)
def readiness(request: Request, response: Response) -> HealthStatus:
    if not getattr(request.app.state, "ready", False):
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return HealthStatus(status="not_ready")

    return HealthStatus(status="ready")


@app.get("/metrics", include_in_schema=False)
def metrics() -> Response:
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)
