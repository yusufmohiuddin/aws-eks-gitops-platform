# Metrics Server

Argo CD installs official Metrics Server chart 3.14.0 into `kube-system` with two
replicas and disruption protection. It supplies the Kubernetes resource metrics
API used by `kubectl top` and the reference workload's CPU-based Horizontal Pod
Autoscaler. Prometheus serves monitoring and alerting; it is not a replacement
for this API.
