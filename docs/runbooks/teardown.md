# Tear down the development platform

## Purpose

Remove billable development resources in dependency-safe order while retaining
the separate Terraform state bucket for future rebuilds and audit history.

## Procedure

Confirm the AWS account and Kubernetes context, then run:

```bash
CONFIRM_DESTROY=aws-eks-gitops-platform-dev make cloud-destroy
```

The guard requires the exact environment name. The script removes Argo CD
Applications first so Kubernetes-created resources do not block VPC deletion,
uninstalls Argo CD, creates a Terraform destroy plan, and applies that plan.

## Post-destroy verification

- Terraform reports no managed development resources.
- EKS, worker nodes, NAT Gateway, ECR, KMS key, and development log groups are
  absent.
- The bootstrap S3 state bucket remains and may incur negligible storage cost.
- No local destroy plan remains.

The bootstrap bucket has deletion protection. Delete it only through the
separate bootstrap procedure after its object versions are intentionally purged.
