# ADR-0005: Use GitHub OIDC for artifact publishing

- Status: Accepted
- Date: 2026-08-25
- Owners: Platform Engineering

## Context

GitHub Actions must publish application images to Amazon ECR. Static AWS access
keys create long-lived credentials, rotation work, and a secret-exfiltration
risk. The publishing workflow does not require Kubernetes or general AWS access.

## Decision

Federate GitHub Actions with AWS through the GitHub OIDC provider. Restrict the
role trust policy to the `main` branch of this repository and the AWS STS
audience. Issue sessions for at most one hour.

Grant the role only ECR authentication and layer/image upload actions against
the reference-service repository. Do not grant Kubernetes, Terraform, IAM, or
general AWS permissions.

Before publishing, build and scan the image for high and critical
vulnerabilities and generate an SPDX SBOM. Publish an immutable commit-SHA tag
with BuildKit provenance and SBOM attestations. Record the resulting image
digest as the release identity.

## Consequences

Benefits:

- GitHub stores no permanent AWS access keys
- credentials are short-lived and scoped to one workflow execution
- pull requests and forks cannot assume the publishing role
- the role cannot deploy workloads or modify infrastructure
- image digest, SBOM, and provenance provide traceable release evidence

Tradeoffs:

- the repository must configure the Terraform output as the
  `AWS_ECR_PUBLISH_ROLE_ARN` GitHub variable after apply
- GitHub OIDC and AWS trust-policy claims must remain aligned
- rebuilding for publication after local scanning increases CI time
- vulnerability exceptions require an explicit reviewed process

## Alternatives considered

### GitHub repository secrets containing AWS keys

This is simple but creates long-lived credentials and rotation obligations and
was rejected.

### A single CI/CD administrator role

One broad role is easier to configure but violates least privilege and could
turn an application build compromise into infrastructure or cluster access.

### CI deployment directly to EKS

This bypasses GitOps reconciliation and gives the build system Kubernetes
credentials. The publishing workflow must stop at the artifact boundary.

## Verification

- Terraform validates the OIDC provider, trust policy, role, and scoped policy.
- pull-request and fork token subjects cannot assume the publishing role.
- a `main` workflow obtains temporary credentials without AWS secrets.
- ECR accepts the immutable image and exposes its digest.
- Trivy passes before publication and the workflow retains an SPDX SBOM.
- the published image includes provenance and SBOM attestations.
- the role cannot access EKS or change Terraform-managed infrastructure.
