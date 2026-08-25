#!/usr/bin/env bash
set -euo pipefail

readonly CLUSTER_NAME="${CLUSTER_NAME:-eks-gitops-platform}"
readonly KUBE_CONTEXT="kind-${CLUSTER_NAME}"
readonly RELEASE_NAME="platform-reference-service"
readonly NAMESPACE="platform-system"
readonly LOCAL_PORT="${LOCAL_PORT:-18081}"

if ! kind get clusters 2>/dev/null | grep -Fxq "${CLUSTER_NAME}"; then
  echo "Local cluster does not exist. Run: make local-up" >&2
  exit 1
fi

pod_name="$(
  kubectl --context "${KUBE_CONTEXT}" get pods \
    --namespace "${NAMESPACE}" \
    --selector app.kubernetes.io/name=platform-reference-service \
    --output jsonpath='{.items[0].metadata.name}'
)"

kubectl --context "${KUBE_CONTEXT}" exec \
  --namespace "${NAMESPACE}" "${pod_name}" -- id

if kubectl --context "${KUBE_CONTEXT}" exec \
  --namespace "${NAMESPACE}" "${pod_name}" -- \
  sh -c 'touch /write-test' 2>/dev/null; then
  echo "Read-only root filesystem verification failed" >&2
  exit 1
fi

echo "read-only-root-filesystem=verified"

kubectl --context "${KUBE_CONTEXT}" port-forward \
  --namespace "${NAMESPACE}" \
  "service/${RELEASE_NAME}" \
  "${LOCAL_PORT}:80" >/tmp/platform-reference-port-forward.log 2>&1 &
port_forward_pid=$!
trap 'kill "${port_forward_pid}" >/dev/null 2>&1 || true' EXIT

for _ in {1..20}; do
  if curl --fail --silent "http://127.0.0.1:${LOCAL_PORT}/health/ready" >/dev/null; then
    break
  fi
  sleep 1
done

curl --fail --silent "http://127.0.0.1:${LOCAL_PORT}/version"
printf '\n'
curl --fail --silent "http://127.0.0.1:${LOCAL_PORT}/metrics" \
  | grep 'platform_reference_build_info'

echo "local-deployment=verified"
