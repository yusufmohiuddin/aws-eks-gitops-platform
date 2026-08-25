# GitOps desired state

This directory is the deployment control plane stored in Git.

- `bootstrap/` defines restricted Argo CD projects and Applications.
- `environments/dev/` contains reviewed environment-specific Helm values.
- image promotion automation changes the ECR repository, SHA-256 digest, and
  source Git SHA; it does not contact Kubernetes.
- Argo CD reads `main`, detects drift, and reconciles approved state.

The initial placeholder image is intentional. The bootstrap script refuses to
register Applications until the first verified image promotion is merged.
