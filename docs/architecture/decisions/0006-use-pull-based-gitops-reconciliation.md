# ADR-0006: Use pull-based GitOps reconciliation

- Status: Accepted
- Date: 2026-08-25
- Owners: Platform Engineering

## Context

A published container is not approval to run it. Direct deployment from CI
would place cluster credentials in the build system, combine artifact creation
with production mutation, and leave the live state harder to audit and recover.

## Decision

GitHub Actions publishes an immutable ECR artifact, then uses a short-lived
GitHub App token to propose a pull request that changes only the ECR repository,
image digest, and source Git SHA in the development desired-state file.

A human reviews and merges that proposal. Argo CD, running inside EKS, pulls the
approved `main` state, compares it with the cluster, and reconciles drift. CI
has no Kubernetes credentials. Automatic pruning and self-healing are enabled
within a restricted Argo CD AppProject.

Argo CD is installed from the pinned `argo-cd` Helm chart version 10.4.0.
Applications use multi-source definitions so chart code, environment values,
and external observability dependencies remain independently identifiable.

## Consequences

Benefits:

- build compromise does not provide direct cluster access
- every deployment has source, artifact digest, review, and Git history
- desired-state rollback is a Git revert
- Argo CD continuously detects and repairs unauthorized drift
- the same process can promote artifacts between environments

Tradeoffs:

- deployment is eventually consistent rather than an immediate CI push
- the delivery GitHub App requires one-time configuration
- Argo CD becomes a critical in-cluster control-plane component
- automated pruning requires careful review of deletions

## Alternatives considered

### CI runs Helm against EKS

Rejected because the build system would need Kubernetes credentials and its
mutation would not be continuously reconciled from reviewed state.

### Mutable image tags

Rejected because a tag can point to different bytes over time and cannot provide
reproducible rollback or release identity.

### GitHub `GITHUB_TOKEN` for promotion pull requests

Rejected because pull requests created by that token do not reliably initiate
normal downstream workflow events. A narrowly permissioned GitHub App produces
a short-lived token and preserves the full review/check path.

## Verification

- promotion input validation rejects mutable tags, malformed digests, and
  non-ECR repositories
- the promotion PR changes only reviewed desired state
- Argo CD reports both applications Synced and Healthy
- the running Deployment image ends in the approved SHA-256 digest
- manual workload drift is detected and reconciled
- reverting the promotion commit returns the workload to the prior digest
