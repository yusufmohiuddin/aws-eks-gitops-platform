# Development environment

This root module composes the disposable AWS development platform. The first increment creates its networking foundation; ECR, EKS, IAM, and platform bootstrap will be added to the same remote state in subsequent reviewed changes.

## Network design

- one `/16` VPC across two Availability Zones
- two private `/20` subnets for EKS worker nodes
- two public `/20` subnets for internet-facing load balancers and NAT placement
- DNS support and hostnames enabled for EKS
- no automatic public IPv4 addresses on instances
- one NAT Gateway for the disposable development environment
- Kubernetes subnet-discovery tags

A single NAT Gateway reduces development cost but creates an Availability Zone dependency. A production environment should use one NAT Gateway per Availability Zone or a reviewed private-egress design. VPC flow logs are configurable and disabled for the temporary lab to avoid CloudWatch ingestion and storage charges.

## Local initialization

Create the ignored backend configuration from the example and replace `ACCOUNT_ID`:

```bash
cp infrastructure/environments/dev/backend.hcl.example infrastructure/environments/dev/backend.hcl
terraform -chdir=infrastructure/environments/dev init -backend-config=backend.hcl
terraform -chdir=infrastructure/environments/dev validate
terraform -chdir=infrastructure/environments/dev plan -out=tfplan
```

The NAT Gateway begins hourly billing only after apply. Review the complete plan and teardown procedure before creating the environment.

## ECR and EKS foundation

The environment also provisions one immutable, scan-on-push ECR repository and an EKS 1.35 cluster using the AWS API authentication mode. Worker nodes run only in private subnets across two Availability Zones.

The development data plane uses two on-demand `t3.medium` instances with encrypted `gp3` root volumes and IMDSv2 enforcement. EKS control-plane API access is private inside the VPC and publicly reachable only from explicitly trusted CIDRs. Kubernetes add-on versions are pinned to versions supported by EKS 1.35.

Control-plane API, audit, and authenticator logs are retained for seven days. Cluster deletion protection remains disabled because this environment is intentionally disposable; production environments should use a separate protection and change-management policy.

The EKS control plane, two EC2 nodes, NAT Gateway, public IPv4 address, EBS volumes, CloudWatch logs, and transferred data incur charges after apply. Do not apply until the entire delivery and teardown workflow is ready for a bounded validation window.
