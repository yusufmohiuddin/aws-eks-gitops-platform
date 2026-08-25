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
