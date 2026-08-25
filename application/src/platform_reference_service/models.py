from typing import Literal

from pydantic import BaseModel


class ServiceIdentity(BaseModel):
    service: str
    environment: str
    status: Literal["running"] = "running"


class VersionInformation(BaseModel):
    service: str
    version: str
    git_sha: str
    environment: str


class HealthStatus(BaseModel):
    status: Literal["alive", "ready", "not_ready"]
