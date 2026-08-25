#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
environment_dir="${repo_root}/infrastructure/environments/dev"
expected_confirmation="aws-eks-gitops-platform-dev"

if [[ "${CONFIRM_DESTROY:-}" != "${expected_confirmation}" ]]; then
  echo "Refusing destructive operation." >&2
  echo "Run: CONFIRM_DESTROY=${expected_confirmation} make cloud-destroy" >&2
  exit 1
fi

aws sts get-caller-identity >/dev/null
if kubectl config get-contexts "${expected_confirmation}" >/dev/null 2>&1; then
  kubectl config use-context "${expected_confirmation}" >/dev/null
  kubectl -n argocd delete applications.argoproj.io --all --wait=true --timeout=10m 2>/dev/null || true
  helm uninstall argo-cd --namespace argocd --wait --timeout 5m 2>/dev/null || true
fi

terraform -chdir="${environment_dir}" plan -destroy -out=destroy.tfplan
terraform -chdir="${environment_dir}" apply destroy.tfplan
rm -f "${environment_dir}/destroy.tfplan"
echo "Development platform destroyed. The separate Terraform state bucket is intentionally retained."
