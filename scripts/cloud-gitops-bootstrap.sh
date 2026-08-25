#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
values_file="${repo_root}/platform/gitops/environments/dev/platform-reference-service/values.yaml"
argocd_chart_version="10.4.0"

for command_name in kubectl helm openssl; do
  command -v "${command_name}" >/dev/null || { echo "${command_name} is required" >&2; exit 1; }
done

if grep -q 'pending-ecr-publication\|digest: ""' "${values_file}"; then
  echo "No approved image digest exists. Publish the image and merge its promotion PR first." >&2
  exit 1
fi

current_context="$(kubectl config current-context)"
case "${current_context}" in
  aws-eks-gitops-platform-dev) ;;
  *) echo "Refusing to bootstrap unexpected context: ${current_context}" >&2; exit 1 ;;
esac

kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -
if ! kubectl -n observability get secret grafana-admin >/dev/null 2>&1; then
  grafana_password="$(openssl rand -base64 30)"
  kubectl -n observability create secret generic grafana-admin \
    --from-literal=admin-user=admin \
    --from-literal="admin-password=${grafana_password}"
  unset grafana_password
fi

helm repo add argo https://argoproj.github.io/argo-helm --force-update
helm repo update argo
helm upgrade --install argo-cd argo/argo-cd \
  --version "${argocd_chart_version}" \
  --namespace argocd \
  --create-namespace \
  --values "${repo_root}/platform/gitops/bootstrap/argocd-values.yaml" \
  --wait \
  --timeout 10m

kubectl -n argocd wait --for=condition=Available deployment/argo-cd-argocd-server --timeout=5m
kubectl apply -f "${repo_root}/platform/gitops/bootstrap/project.yaml"
kubectl apply -f "${repo_root}/platform/gitops/bootstrap/applications/observability.yaml"

for _ in {1..90}; do
  sync_status="$(kubectl -n argocd get application observability -o jsonpath='{.status.sync.status}' 2>/dev/null || true)"
  health_status="$(kubectl -n argocd get application observability -o jsonpath='{.status.health.status}' 2>/dev/null || true)"
  if [[ "${sync_status}" == "Synced" && "${health_status}" == "Healthy" ]]; then
    break
  fi
  sleep 10
done
if [[ "${sync_status:-}" != "Synced" || "${health_status:-}" != "Healthy" ]]; then
  kubectl -n argocd get application observability -o yaml >&2
  echo "Observability did not become Synced and Healthy before timeout." >&2
  exit 1
fi

# The workload owns ServiceMonitor and PrometheusRule resources, so register it
# only after the observability operator has installed their CRDs.
kubectl apply -f "${repo_root}/platform/gitops/bootstrap/applications/metrics-server.yaml"
kubectl apply -f "${repo_root}/platform/gitops/bootstrap/applications/platform-reference-service.yaml"

printf 'Argo CD installed; approved applications are reconciling from Git.\n'
