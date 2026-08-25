# Platform Reference Service Helm Chart

This chart packages the platform reference workload for Kubernetes deployment.
It provides secure workload defaults, health probes, resource controls, rolling
updates, disruption protection, optional autoscaling, topology spreading, and
network isolation.

## Validate

```bash
helm lint .
helm template platform-reference-service . --namespace platform-system
```

## Local image

For a local cluster, load `platform-reference-service:local` into the cluster
and install with the default `IfNotPresent` pull policy.

## Immutable deployment

For shared environments, set `image.repository` and `image.digest`. When a
digest is present, the chart renders an immutable OCI image reference and
ignores `image.tag`.
