# ADR-0003: Use private multi-AZ EKS networking

- Status: Accepted
- Date: 2026-08-25
- Owners: Platform Engineering

## Context

EKS worker nodes require resilient network placement and outbound access for
container images, package repositories, and AWS APIs. Internet-facing load
balancers require discoverable public subnets, but worker nodes should not
receive public IPv4 addresses.

The development environment must demonstrate the production network pattern
without leaving unnecessary hourly resources running between test sessions.

## Decision

Create one `/16` VPC across two Availability Zones with two private `/20`
subnets and two public `/20` subnets. Place EKS worker nodes in private subnets
and reserve public subnets for internet-facing load balancers and NAT placement.
Disable automatic public IPv4 assignment and enable VPC DNS support.

Use one NAT Gateway for the disposable development environment. Keep the NAT
Gateway configurable so it can be disabled when the environment does not need
private outbound access. Apply the environment only for active integration
validation and destroy it afterward.

Tag subnets for Kubernetes load-balancer discovery. Keep VPC flow logs
configurable and disabled in the temporary lab to avoid CloudWatch ingestion
and storage charges.

A production environment must use one NAT Gateway per Availability Zone or an
approved private-egress design with the required VPC endpoints.

## Consequences

Benefits:

- worker nodes have no direct public ingress path
- workloads and load balancers have explicit subnet boundaries
- two Availability Zones support scheduler and disruption testing
- one development NAT Gateway reduces temporary validation cost
- CIDR allocation leaves substantial space for pod and service growth

Tradeoffs:

- one NAT Gateway creates an Availability Zone dependency in development
- cross-AZ egress can incur data-transfer cost
- NAT Gateway hourly and processing charges begin immediately after apply
- disabled flow logs reduce network-forensics evidence in the temporary lab

## Alternatives considered

### Public worker nodes

This is cheaper and simpler but unnecessarily exposes node network interfaces
and does not represent the target security architecture.

### One NAT Gateway per Availability Zone

This removes the cross-AZ dependency and is the production preference, but it
doubles the fixed NAT cost for a short-lived learning environment.

### Interface endpoints without NAT

A private endpoint design can reduce internet dependency, but ECR, STS,
CloudWatch, and other interface endpoints have hourly per-AZ costs and add
complexity. It should be evaluated for long-running regulated environments,
not assumed to be cheaper for this disposable platform.

## Verification

- Terraform validation and Trivy infrastructure scanning pass.
- The reviewed plan creates resources in exactly two Availability Zones.
- Private subnets do not assign public IPv4 addresses.
- Public and private route tables use the intended internet and NAT paths.
- Kubernetes subnet-discovery tags are present.
- Post-apply tests verify private-node egress and the absence of direct ingress.
- Teardown confirms the NAT Gateway and Elastic IP are removed.
