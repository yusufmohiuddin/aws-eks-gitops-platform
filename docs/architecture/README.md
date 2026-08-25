# Architecture

The platform separates three authority domains: Terraform owns AWS resources,
CI owns artifact production, and Argo CD owns Kubernetes reconciliation.

```mermaid
flowchart LR
    E[Engineer] -->|application PR| CI[GitHub Actions\ntest · scan · build]
    CI -->|OIDC, least privilege| ECR[Amazon ECR\nimmutable digest · SBOM · provenance]
    ECR --> BOT[Delivery GitHub App\nshort-lived token]
    BOT -->|promotion PR| REVIEW{Human review}
    REVIEW -->|merge digest| GIT[GitOps desired state\nmain branch]
    GIT -->|pull and compare| ARGO[Argo CD\nin Amazon EKS]
    ARGO -->|reconcile| APP[Reference workload\nprivate worker nodes]
    APP -->|ServiceMonitor| PROM[Prometheus]
    PROM --> GRAF[Grafana]
    PROM --> ALERT[Alertmanager]
    TF[Terraform plan + approval] -->|provision| AWS[VPC · EKS · ECR · IAM · KMS]
    AWS --> ARGO
```

## Trust boundaries

- GitHub authenticates to AWS with OIDC; no AWS access key is stored in GitHub.
- The publishing role can upload only to one ECR repository and cannot access EKS.
- A repository-scoped GitHub App can propose Git changes but cannot deploy them.
- Human approval converts a verified artifact into approved desired state.
- Argo CD runs inside the cluster and is the only automated workload reconciler.
- EKS workers are private; the API permits only explicitly trusted CIDRs.

## Decision records

Architecture Decision Records document choices that materially affect security,
reliability, operability, cost, or maintainability. Accepted decisions are
changed through a new record rather than silently rewriting their history.
