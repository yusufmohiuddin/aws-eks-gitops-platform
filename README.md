# AWS EKS GitOps Platform

An AWS platform for secure, declarative application delivery to Amazon EKS.

The platform uses Terraform to provision cloud infrastructure, GitHub Actions
to validate changes and publish immutable container images, and Argo CD to
reconcile approved deployment state into Kubernetes.

## Architecture

The delivery model separates infrastructure provisioning, artifact production,
and workload deployment:

1. Terraform provisions the AWS and EKS foundation.
2. GitHub Actions tests and scans application changes.
3. Approved container images are published to Amazon ECR.
4. Deployment state is updated through a reviewed pull request.
5. Argo CD reconciles the declared state into Amazon EKS.
6. Prometheus and Grafana provide operational visibility.

The CI pipeline does not deploy workloads directly to Kubernetes.

## Repository structure

| Path | Responsibility |
|---|---|
| `application/` | Application source, tests, and container definition |
| `infrastructure/` | Terraform modules and environment composition |
| `platform/helm/` | Kubernetes workload packaging |
| `platform/gitops/` | Declarative environment state |
| `platform/observability/` | Metrics, dashboards, and alerting |
| `docs/architecture/` | Architecture documentation and decision records |
| `docs/runbooks/` | Operational and incident-response procedures |
| `.github/workflows/` | Continuous integration and delivery workflows |
| `scripts/` | Repeatable development and operational utilities |

## Engineering principles

- Infrastructure and deployment state are defined as code.
- Production changes require review and leave an auditable history.
- Workloads use immutable container references.
- Automation uses short-lived credentials and least-privilege access.
- Security controls run throughout the delivery lifecycle.
- Health, performance, and failure modes are observable.
- Deployments and infrastructure changes are reversible.
- Operational procedures are documented and tested.

## Status

The platform foundation is under active development. Implementation evidence,
verification procedures, and architectural decisions will be documented as
each capability is introduced.
