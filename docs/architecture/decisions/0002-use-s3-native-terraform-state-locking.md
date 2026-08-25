# ADR-0002: Use S3-native Terraform state locking

- Status: Accepted
- Date: 2026-08-24
- Owners: Platform Engineering

## Context

Terraform requires durable shared state, concurrency protection, encryption,
and a recovery path. The backend must exist before environment infrastructure
can use it, and it must remain available when disposable environments are
destroyed.

Older AWS implementations commonly combined S3 state storage with a DynamoDB
lock table. Terraform now supports S3 lockfiles and deprecates DynamoDB-based
locking. Maintaining both mechanisms would add an unnecessary resource and
permission surface.

## Decision

Create a dedicated, deletion-protected S3 bucket in a one-time bootstrap root
module. Enable versioning, S3-managed AES-256 encryption, bucket-owner-enforced
object ownership, Block Public Access, and a TLS-only bucket policy.

Use partial backend configuration and `use_lockfile = true`. Keep credentials,
account-specific backend configuration, saved plans, and state files outside
version control. After the initial local bootstrap, migrate the bootstrap state
into the new S3 backend.

Environment teardown must not remove the shared state bucket.

## Consequences

Benefits:

- concurrent Terraform operations cannot silently overwrite state
- versioned state supports recovery from accidental changes or deletion
- no DynamoDB table, billing surface, or permissions are required for locking
- environment infrastructure can be destroyed without losing its state history
- backend configuration contains no long-lived AWS credentials

Tradeoffs:

- the first bootstrap operation temporarily uses local state
- operators must complete and verify the state migration
- S3-managed encryption does not provide an independent customer-managed key
  policy or rotation boundary
- deliberate removal requires a separate recovery-aware procedure

A customer-managed KMS key should replace SSE-S3 when regulatory controls,
separation of duties, or independent key auditing justify its recurring cost.

## Alternatives considered

### S3 with DynamoDB locking

This is widely recognized but DynamoDB locking is deprecated. It creates an
extra resource and IAM surface without improving this platform's current
locking requirements.

### HCP Terraform

HCP Terraform provides managed state, locking, policy, and run history, but it
introduces an external service and does not demonstrate the AWS-native backend
controls selected for this platform.

### Local state

Local state is sufficient only during the unavoidable first bootstrap. It is
not acceptable for shared environment infrastructure because it lacks durable
collaboration and locking.

## Verification

- Terraform formatting and validation pass in CI.
- Trivy reports no unapproved high or critical infrastructure findings.
- A reviewed plan contains only the expected bootstrap resources.
- S3 versioning, encryption, Block Public Access, ownership controls, and the
  TLS-only policy are verified after creation.
- The migrated bootstrap state is readable from S3 with lockfile support.
- A concurrent locking test prevents a second writer from acquiring the state.
