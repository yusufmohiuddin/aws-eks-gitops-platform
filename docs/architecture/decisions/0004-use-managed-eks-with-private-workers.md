# ADR-0004: Use managed EKS with private workers

- Status: Accepted
- Date: 2026-08-25
- Owners: Platform Engineering

## Context

The platform requires a Kubernetes control plane that demonstrates secure AWS
integration, upgrade awareness, auditable access, resilient workload placement,
and repeatable teardown. The development environment must remain small enough
for bounded validation while preserving the architecture used by engineering
teams in production.

## Decision

Provision Amazon EKS 1.35 with the pinned `terraform-aws-eks` module. Version
1.35 is under EKS standard support through March 2027, avoiding extended-support
charges while providing a mature release window.

Use EKS API access entries instead of the legacy `aws-auth` ConfigMap. Grant the
bootstrap administrator through an explicit access entry. Enable private API
access and restrict the public endpoint to operator-provided trusted CIDRs.

Run two on-demand `t3.medium` managed nodes in private subnets across two
Availability Zones. Use Amazon Linux 2023, encrypted `gp3` volumes, IMDSv2,
rolling updates, and pinned EKS managed add-ons. Enable API, audit, and
authenticator control-plane logs with seven-day retention.

Create a rotating customer-managed KMS key for Kubernetes secrets envelope
encryption. Keep cluster deletion protection disabled only because the
development environment is intentionally disposable and must be torn down after
verification.

Create a private ECR repository with immutable tags, scan-on-push, encryption,
and lifecycle retention. CI will ultimately publish images by digest through a
separate least-privilege GitHub OIDC role.

## Consequences

Benefits:

- AWS manages control-plane availability and patching
- worker nodes have no public IPv4 addresses
- API authentication and authorization are auditable AWS resources
- two nodes permit disruption, rollout, and scheduling tests
- secret data receives envelope encryption with an independently controlled key
- immutable, scanned images improve release identity and supply-chain controls

Tradeoffs:

- the EKS control plane, EC2 nodes, NAT Gateway, KMS key, logs, storage, and data
  transfer incur charges while the environment exists
- two `t3.medium` nodes are suitable for validation, not production capacity
- one development NAT Gateway remains an Availability Zone dependency
- cluster administrator access is broad during bootstrap and must not become an
  application delivery credential
- the public API endpoint remains reachable only from explicitly trusted CIDRs
  because the operator is outside the VPC

## Alternatives considered

### EKS Auto Mode

Auto Mode reduces data-plane administration, but managed node groups expose the
launch template, IAM, storage, update, and scaling decisions this platform is
intended to demonstrate and test.

### Self-managed Kubernetes on EC2

This provides control over every component but adds control-plane operations
that are outside the delivery-platform objective.

### Spot-only worker nodes

Spot reduces compute cost but can interrupt installation and operational tests.
On-demand nodes provide deterministic bounded validation; mixed capacity can be
added for production workload pools.

### Public worker nodes

Public nodes reduce network cost but weaken the intended private-workload
boundary and are not selected.

## Verification

- Terraform validation and IaC security scanning pass.
- A reviewed plan contains no changes or destroys before initial apply.
- EKS reports Kubernetes 1.35 and ACTIVE status.
- both managed nodes become Ready in separate Availability Zones
- public API access rejects addresses outside the trusted CIDR
- node interfaces have no public IPv4 addresses and enforce IMDSv2
- root volumes are encrypted and managed add-on versions match configuration
- ECR rejects mutable tag replacement and reports image scan findings
- audit logs arrive in CloudWatch with seven-day retention
- teardown removes EKS, nodes, NAT, EIP, logs, ECR images, and networking
