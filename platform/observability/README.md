# Platform observability

The development environment uses a pinned kube-prometheus-stack release managed
by Argo CD. The official pinned Metrics Server chart supplies the resource metrics
API required by the workload HPA. Prometheus discovers the reference workload through ServiceMonitor,
Grafana visualizes platform and Kubernetes signals, and Alertmanager receives
reviewed rules.

Retention and resources are intentionally bounded for a disposable environment.
Production adoption requires durable storage, external alert routing, SSO,
backups, and sizing based on measured cardinality and ingestion.
