#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chart_path="${repo_root}/platform/helm/platform-reference-service"
release_name="platform-reference-service"
namespace="platform-system"
digest="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

helm lint "${chart_path}"

default_manifest="$(mktemp)"
digest_manifest="$(mktemp)"
autoscaling_manifest="$(mktemp)"
trap 'rm -f "${default_manifest}" "${digest_manifest}" "${autoscaling_manifest}"' EXIT

helm template "${release_name}" "${chart_path}" \
  --namespace "${namespace}" >"${default_manifest}"

grep -Fq 'image: "platform-reference-service:local"' "${default_manifest}"
grep -Fq 'automountServiceAccountToken: false' "${default_manifest}"
grep -Fq 'readOnlyRootFilesystem: true' "${default_manifest}"
grep -Fq 'allowPrivilegeEscalation: false' "${default_manifest}"
grep -Fq 'kind: PodDisruptionBudget' "${default_manifest}"
grep -Fq 'kind: NetworkPolicy' "${default_manifest}"

helm template "${release_name}" "${chart_path}" \
  --namespace "${namespace}" \
  --set-string "image.digest=${digest}" >"${digest_manifest}"

grep -Fq "image: \"platform-reference-service@${digest}\"" "${digest_manifest}"

helm template "${release_name}" "${chart_path}" \
  --namespace "${namespace}" \
  --set autoscaling.enabled=true >"${autoscaling_manifest}"

grep -Fq 'kind: HorizontalPodAutoscaler' "${autoscaling_manifest}"
if grep -Eq '^[[:space:]]+replicas:' "${autoscaling_manifest}"; then
  echo "Deployment must omit replicas when autoscaling is enabled" >&2
  exit 1
fi

echo "Helm chart render checks passed."
