#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
environment_dir="${repo_root}/infrastructure/environments/dev"

command -v aws >/dev/null || { echo "aws is required" >&2; exit 1; }
command -v terraform >/dev/null || { echo "terraform is required" >&2; exit 1; }

aws sts get-caller-identity >/dev/null
cluster_name="$(terraform -chdir="${environment_dir}" output -raw eks_cluster_name)"
region="$(terraform -chdir="${environment_dir}" output -raw aws_region 2>/dev/null || true)"
region="${region:-us-east-1}"
context_alias="${cluster_name}"

aws eks update-kubeconfig --region "${region}" --name "${cluster_name}" --alias "${context_alias}"
kubectl config use-context "${context_alias}" >/dev/null
kubectl cluster-info
printf 'Kubernetes context configured: %s\n' "${context_alias}"
