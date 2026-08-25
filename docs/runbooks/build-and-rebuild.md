# Build and rebuild the development platform

## Purpose

Create the complete disposable AWS EKS GitOps environment from reviewed source.
The Terraform state bucket is a separate retained prerequisite.

## Prerequisites

- authenticated AWS CLI session for the intended non-root administrator
- Terraform, AWS CLI, Docker, kubectl, Helm, uv, and GitHub CLI
- ignored `backend.hcl` and `terraform.tfvars` files created from their examples
- trusted operator `/32` configured for the EKS public API
- required pull-request checks passing on `main`

## Procedure

1. Confirm identity with `aws sts get-caller-identity`.
2. Run `make cloud-plan` and review every create, change, and destroy action.
3. Run `make cloud-apply` only for a bounded validation window.
4. Configure repository variable `AWS_ECR_PUBLISH_ROLE_ARN` from Terraform output.
5. Configure the delivery GitHub App described in `docs/runbooks/github-delivery-app.md`.
6. Manually dispatch `application-delivery` to publish the first image.
7. Review and merge the generated digest-promotion pull request.
8. Run `make cloud-kubeconfig`.
9. Run `make gitops-bootstrap`.
10. Run `make cloud-verify` and retain the output as evidence.

Rebuilding follows the same sequence. Terraform recreates the foundation, the
publisher produces an image for the new ECR repository, and Argo CD reconstructs
the cluster from approved Git state.

## Failure handling

Do not repeatedly apply after an unexplained error. Preserve the plan and error,
inspect AWS events and Terraform state, correct source, run a new plan, and
continue through review. If the validation window cannot be completed, follow
the teardown runbook to stop billable resources.

## Access for the bounded demonstration

Argo CD and Grafana remain ClusterIP-only. Use `kubectl port-forward` rather
than exposing public load balancers. Retrieve their generated or bootstrap
credentials from Kubernetes Secrets only when needed. A long-lived environment
should replace local administrators with SSO and managed secret delivery.
