# Terraform state bootstrap

This root module creates the shared S3 bucket used by Terraform backends. It is intentionally separate from environment infrastructure because the backend must exist before an environment can store its state remotely.

## Controls

- account- and Region-qualified bucket naming
- S3 Block Public Access
- bucket-owner-enforced object ownership
- default S3-managed AES-256 encryption, avoiding a recurring customer-managed KMS key charge for the lab
- versioning for state recovery
- TLS-only bucket policy
- deletion protection
- Terraform S3 lockfiles; no deprecated DynamoDB locking

The Trivy exception for `AVD-AWS-0132` records this deliberate cost decision. A regulated or shared production deployment should replace SSE-S3 with a customer-managed KMS key when independent key policy, auditing, or rotation control is required.

## Bootstrap workflow

Authenticate with a non-root AWS identity and confirm the target account before continuing.

```bash
aws sts get-caller-identity
terraform -chdir=infrastructure/bootstrap init -backend=false
terraform -chdir=infrastructure/bootstrap fmt -check
terraform -chdir=infrastructure/bootstrap validate
terraform -chdir=infrastructure/bootstrap plan -out=tfplan
terraform -chdir=infrastructure/bootstrap apply tfplan
```

After the bucket exists, copy the backend templates to their ignored runtime files, replace `ACCOUNT_ID`, and migrate the bootstrap state into S3:

```bash
cp infrastructure/bootstrap/backend.tf.example infrastructure/bootstrap/backend.tf
cp infrastructure/bootstrap/backend.hcl.example infrastructure/bootstrap/backend.hcl
terraform -chdir=infrastructure/bootstrap init \
  -migrate-state \
  -force-copy \
  -backend-config=backend.hcl
terraform -chdir=infrastructure/bootstrap state list
```

Never commit `backend.hcl`, Terraform state, saved plans, credentials, or account-specific values. Environment teardown does not delete this shared state bucket. Removing it requires an explicit recovery-aware procedure because versioned state objects may be needed after an incident.
