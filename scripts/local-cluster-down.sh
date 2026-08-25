#!/usr/bin/env bash
set -euo pipefail

readonly CLUSTER_NAME="${CLUSTER_NAME:-eks-gitops-platform}"
readonly KUBE_CONTEXT="kind-${CLUSTER_NAME}"
readonly RELEASE_NAME="platform-reference-service"
readonly NAMESPACE="platform-system"

if ! kind get clusters 2>/dev/null | grep -Fxq "${CLUSTER_NAME}"; then
  echo "Local cluster is already absent"
  exit 0
fi

original_context="$(kubectl config current-context 2>/dev/null || true)"

helm uninstall "${RELEASE_NAME}" \
  --kube-context "${KUBE_CONTEXT}" \
  --namespace "${NAMESPACE}" \
  --wait 2>/dev/null || true

kubectl --context "${KUBE_CONTEXT}" delete namespace "${NAMESPACE}" \
  --ignore-not-found \
  --wait=true

kind delete cluster --name "${CLUSTER_NAME}"

if [[ -n "${original_context}" && "${original_context}" != "${KUBE_CONTEXT}" ]]; then
  kubectl config use-context "${original_context}" >/dev/null 2>&1 || true
fi

if kind get clusters 2>/dev/null | grep -Fxq "${CLUSTER_NAME}"; then
  echo "Local cluster teardown verification failed" >&2
  exit 1
fi

echo "local-cluster-lifecycle=destroyed"
