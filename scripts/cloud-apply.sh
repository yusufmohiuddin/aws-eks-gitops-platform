#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
environment_dir="${repo_root}/infrastructure/environments/dev"
expected_confirmation="aws-eks-gitops-platform-dev"
plan_file="${environment_dir}/apply.tfplan"

if [[ "${CONFIRM_APPLY:-}" != "${expected_confirmation}" ]]; then
  echo "Refusing to create billable AWS resources." >&2
  echo "First review make cloud-plan, then run:" >&2
  echo "CONFIRM_APPLY=${expected_confirmation} make cloud-apply" >&2
  exit 1
fi

aws sts get-caller-identity >/dev/null
terraform -chdir="${environment_dir}" plan -out="${plan_file}"
terraform -chdir="${environment_dir}" apply "${plan_file}"
rm -f "${plan_file}"
echo "AWS development foundation applied. Continue with image publication and GitOps bootstrap."
