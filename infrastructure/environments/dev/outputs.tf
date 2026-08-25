output "aws_account_id" {
  description = "AWS account hosting the development platform."
  value       = data.aws_caller_identity.current.account_id
}

output "vpc_id" {
  description = "Development VPC identifier."
  value       = module.vpc.vpc_id
}

output "availability_zones" {
  description = "Availability Zones used by the platform."
  value       = local.azs
}

output "private_subnet_ids" {
  description = "Private subnet identifiers for EKS worker nodes."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet identifiers for internet-facing load balancers."
  value       = module.vpc.public_subnets
}

output "nat_gateway_public_ips" {
  description = "Public IP addresses assigned to NAT gateways."
  value       = module.vpc.nat_public_ips
}
