# ADR-0007: Use kube-prometheus-stack for platform observability

- Status: Accepted
- Date: 2026-08-25
- Owners: Platform Engineering

## Context

A successful Kubernetes rollout does not prove that a service is healthy over
time. Operators need workload, Kubernetes, and node signals plus actionable
alerts. The disposable development environment also requires bounded memory and
retention settings.

## Decision

Deploy the pinned `kube-prometheus-stack` Helm chart version 88.5.4 through Argo
CD. Deploy Metrics Server chart 3.14.0 separately to supply the Kubernetes resource
metrics API used by Horizontal Pod Autoscaling. Run Prometheus, Alertmanager, Grafana, kube-state-metrics, and node exporter
in the `observability` namespace.

Expose application metrics through a ServiceMonitor. Add Prometheus rules for
loss of available replicas and a sustained HTTP 5xx ratio above five percent.
Use six-hour, five-gigabyte Prometheus retention without persistent volumes for
the disposable validation environment. Create the Grafana administrator secret
at bootstrap time instead of storing a password in Git.

## Consequences

Benefits:

- Kubernetes health and application behavior are visible in one stack
- alerts encode availability expectations as reviewed configuration
- ServiceMonitor discovery keeps scraping declarative
- Metrics Server makes CPU-based HPA behavior verifiable
- credentials remain outside source control
- bounded ephemeral retention limits development cost and cleanup work

Tradeoffs:

- telemetry disappears when the disposable cluster is destroyed
- the stack consumes capacity on the two-node development cluster
- production requires persistent storage, durable alert routing, SSO, and
  retention sized from measured ingestion

## Verification

- Prometheus discovers the reference-service target
- `/metrics` exposes build identity, request count, and latency
- Grafana and Alertmanager deployments become Available
- a controlled replica-loss test causes the availability rule to become pending
- destroying the cluster leaves no observability volumes behind
