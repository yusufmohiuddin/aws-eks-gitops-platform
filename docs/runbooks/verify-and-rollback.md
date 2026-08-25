# Verify and roll back a deployment

## Automated verification

Run `make cloud-verify`. It verifies AWS authentication, EKS status, Ready nodes,
Argo CD, the application and Grafana deployments, digest pinning, non-root pod
security, readiness/version/metrics endpoints, and a zero-change Terraform plan.

Also record:

```bash
kubectl -n argocd get applications
kubectl -n platform-system get pods -o wide
kubectl -n platform-system get deployment platform-reference-service \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
```

## Drift test

Temporarily scale the Deployment to a different replica count. Argo CD should
report drift and restore the Git-declared configuration. Do not disable
self-healing to make the demonstration pass.

## Rollback

1. Identify the last healthy digest-promotion commit.
2. Revert the faulty promotion commit through a pull request.
3. Review and merge the revert.
4. Observe Argo CD reconcile the previous immutable digest.
5. Run `make cloud-verify` and record the restored `/version` response.

If the application cannot wait for Git reconciliation, an authorized operator
may suspend auto-sync and perform an emergency Argo CD rollback. Immediately
follow it with a Git correction so declared and live state do not diverge.
