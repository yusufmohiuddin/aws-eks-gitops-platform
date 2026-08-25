#!/usr/bin/env bash
set -euo pipefail

readonly CLUSTER_NAME="${CLUSTER_NAME:-eks-gitops-platform}"
readonly KUBE_CONTEXT="kind-${CLUSTER_NAME}"
readonly IMAGE_NAME="${IMAGE_NAME:-platform-reference-service:local}"
readonly RELEASE_NAME="platform-reference-service"
readonly NAMESPACE="platform-system"
readonly CHART_PATH="platform/helm/platform-reference-service"

for command in docker kind kubectl helm; do
  if ! command -v "${command}" >/dev/null 2>&1; then
    echo "Required command not found: ${command}" >&2
    exit 1
  fi
done

docker info >/dev/null
original_context="$(kubectl config current-context 2>/dev/null || true)"

restore_context() {
  if [[ -n "${original_context}" ]]; then
    kubectl config use-context "${original_context}" >/dev/null 2>&1 || true
  fi
}
trap restore_context EXIT

docker build --tag "${IMAGE_NAME}" application

if ! kind get clusters 2>/dev/null | grep -Fxq "${CLUSTER_NAME}"; then
  kind create cluster --name "${CLUSTER_NAME}" --wait 120s
fi

kind load docker-image "${IMAGE_NAME}" --name "${CLUSTER_NAME}"

git_sha="$(git rev-parse --short=12 HEAD)"
image_tag="${IMAGE_NAME##*:}"

helm upgrade --install "${RELEASE_NAME}" "${CHART_PATH}" \
  --kube-context "${KUBE_CONTEXT}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --set "image.tag=${image_tag}" \
  --set image.pullPolicy=Never \
  --set "configuration.gitSha=${git_sha}" \
  --wait \
  --timeout 120s

kubectl --context "${KUBE_CONTEXT}" \
  rollout status "deployment/${RELEASE_NAME}" \
  --namespace "${NAMESPACE}" \
  --timeout=120s

kubectl --context "${KUBE_CONTEXT}" \
  get deployment,pods,service \
  --namespace "${NAMESPACE}"
