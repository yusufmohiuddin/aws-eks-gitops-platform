#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chart_path="${repo_root}/platform/helm/platform-reference-service"
values_file="${repo_root}/platform/gitops/environments/dev/platform-reference-service/values.yaml"
temporary_directory="$(mktemp -d)"
trap 'rm -rf "${temporary_directory}"' EXIT

ruby -e 'require "yaml"; ARGV.each { |path| YAML.safe_load(File.read(path), aliases: true) }' \
  "${repo_root}/platform/gitops/bootstrap/argocd-values.yaml" \
  "${repo_root}/platform/gitops/bootstrap/project.yaml" \
  "${repo_root}/platform/gitops/bootstrap/applications/platform-reference-service.yaml" \
  "${repo_root}/platform/gitops/bootstrap/applications/observability.yaml" \
  "${repo_root}/platform/gitops/bootstrap/applications/metrics-server.yaml" \
  "${repo_root}/platform/observability/kube-prometheus-stack/values.yaml" \
  "${values_file}"

helm lint "${chart_path}" --values "${values_file}"
helm template platform-reference-service "${chart_path}" \
  --namespace platform-system \
  --values "${values_file}" >"${temporary_directory}/application.yaml"
grep -Fq 'kind: ServiceMonitor' "${temporary_directory}/application.yaml"
grep -Fq 'kind: PrometheusRule' "${temporary_directory}/application.yaml"

helm repo add argo https://argoproj.github.io/argo-helm --force-update
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/ --force-update
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm repo update argo prometheus-community metrics-server
helm template argo-cd argo/argo-cd \
  --version 10.4.0 \
  --namespace argocd \
  --values "${repo_root}/platform/gitops/bootstrap/argocd-values.yaml" \
  --skip-tests >"${temporary_directory}/argocd.yaml"
grep -Fq 'kind: Deployment' "${temporary_directory}/argocd.yaml"

helm template kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --version 88.5.4 \
  --namespace observability \
  --values "${repo_root}/platform/observability/kube-prometheus-stack/values.yaml" \
  --skip-tests >"${temporary_directory}/observability.yaml"
grep -Fq 'kind: Prometheus' "${temporary_directory}/observability.yaml"
grep -Fq 'app.kubernetes.io/name: grafana' "${temporary_directory}/observability.yaml"
helm template metrics-server metrics-server/metrics-server --version 3.14.0 --namespace kube-system >"${temporary_directory}/metrics-server.yaml"
grep -Fq 'kind: APIService' "${temporary_directory}/metrics-server.yaml"

echo "GitOps and observability render checks passed."
