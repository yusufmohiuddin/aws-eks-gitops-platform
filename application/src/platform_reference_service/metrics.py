from time import perf_counter

from prometheus_client import Counter, Histogram
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response

HTTP_REQUESTS = Counter(
    "platform_reference_http_requests_total",
    "Total HTTP requests handled by the service.",
    ("method", "route", "status_code"),
)

HTTP_REQUEST_DURATION = Histogram(
    "platform_reference_http_request_duration_seconds",
    "HTTP request duration in seconds.",
    ("method", "route"),
)


class MetricsMiddleware(BaseHTTPMiddleware):
    """Record request counts and latency using bounded route labels."""

    async def dispatch(
        self,
        request: Request,
        call_next: RequestResponseEndpoint,
    ) -> Response:
        started_at = perf_counter()
        response = await call_next(request)
        route = request.scope.get("route")
        route_path = getattr(route, "path", "unmatched")

        HTTP_REQUESTS.labels(
            method=request.method,
            route=route_path,
            status_code=str(response.status_code),
        ).inc()
        HTTP_REQUEST_DURATION.labels(
            method=request.method,
            route=route_path,
        ).observe(perf_counter() - started_at)

        return response
