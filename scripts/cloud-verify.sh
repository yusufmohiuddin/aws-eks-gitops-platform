#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
environment_dir="${repo_root}/infrastructure/environments/dev"

for command_name in aws terraform kubectl; do
  command -v "${command_name}" >/dev/null || { echo "${command_name} is required" >&2; exit 1; }
done

aws sts get-caller-identity >/dev/null
[[ "$(kubectl config current-context)" == "aws-eks-gitops-platform-dev" ]] || {
  echo "Unexpected Kubernetes context; run make cloud-kubeconfig" >&2
  exit 1
}

[[ "$(aws eks describe-cluster --name aws-eks-gitops-platform-dev --query 'cluster.status' --output text)" == "ACTIVE" ]]
kubectl wait --for=condition=Ready nodes --all --timeout=10m
kubectl -n argocd wait --for=condition=Available deployment/argo-cd-argocd-server --timeout=5m
kubectl -n kube-system wait --for=condition=Available deployment/metrics-server --timeout=10m
kubectl top nodes >/dev/null
kubectl -n platform-system wait --for=condition=Available deployment/platform-reference-service --timeout=10m
kubectl -n observability wait --for=condition=Available deployment/kube-prometheus-stack-grafana --timeout=10m

image="$(kubectl -n platform-system get deployment platform-reference-service -o jsonpath='{.spec.template.spec.containers[0].image}')"
[[ "${image}" =~ @sha256:[0-9a-f]{64}$ ]] || { echo "Workload is not digest pinned: ${image}" >&2; exit 1; }

run_as_non_root="$(kubectl -n platform-system get deployment platform-reference-service -o jsonpath='{.spec.template.spec.securityContext.runAsNonRoot}')"
[[ "${run_as_non_root}" == "true" ]]

kubectl -n platform-system port-forward service/platform-reference-service 18080:80 >/tmp/platform-reference-port-forward.log 2>&1 &
port_forward_pid=$!
trap 'kill "${port_forward_pid}" 2>/dev/null || true' EXIT
for _ in {1..30}; do
  curl --fail --silent http://127.0.0.1:18080/health/ready >/dev/null && break
  sleep 2
done
curl --fail --silent http://127.0.0.1:18080/version
curl --fail --silent http://127.0.0.1:18080/metrics | grep -q platform_reference_build_info

terraform -chdir="${environment_dir}" plan -detailed-exitcode -no-color >/tmp/platform-terraform-drift.txt || status=$?
status="${status:-0}"
if [[ "${status}" -eq 2 ]]; then
  echo "Terraform drift detected; inspect /tmp/platform-terraform-drift.txt" >&2
  exit 1
elif [[ "${status}" -ne 0 ]]; then
  cat /tmp/platform-terraform-drift.txt >&2
  exit "${status}"
fi

echo "Cloud platform verification passed: infrastructure, GitOps, workload, security, metrics, and drift."
