variable "aws_region" {
  description = "AWS Region in which the development platform is deployed."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-gov)?-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS Region name."
  }
}

variable "project_name" {
  description = "Stable project identifier used for resource names and tags."
  type        = string
  default     = "aws-eks-gitops-platform"
}

variable "environment" {
  description = "Deployment environment identifier."
  type        = string
  default     = "dev"
}

variable "github_oidc_subject_prefix" {
  description = "Immutable GitHub OIDC repository subject prefix returned by the Actions OIDC customization API."
  type        = string

  validation {
    condition     = can(regex("^repo:[^/]+@[0-9]+/[^@]+@[0-9]+$", var.github_oidc_subject_prefix))
    error_message = "github_oidc_subject_prefix must use GitHub's immutable repo:OWNER@OWNER_ID/REPOSITORY@REPOSITORY_ID format."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR allocated to the development VPC."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "enable_nat_gateway" {
  description = "Create controlled outbound internet access for private workloads. This incurs hourly and data-processing charges."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Publish VPC flow logs to CloudWatch. Disabled in the disposable lab to control ingestion and storage cost."
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "Additional tags merged with the required platform tags."
  type        = map(string)
  default     = {}
}

variable "kubernetes_version" {
  description = "EKS Kubernetes minor version under standard AWS support."
  type        = string
  default     = "1.35"
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "IPv4 CIDRs allowed to reach the public EKS API endpoint. Use trusted /32 addresses for the lab."
  type        = list(string)

  validation {
    condition = length(var.cluster_endpoint_public_access_cidrs) > 0 && alltrue([
      for cidr in var.cluster_endpoint_public_access_cidrs : can(cidrnetmask(cidr)) && cidr != "0.0.0.0/0"
    ])
    error_message = "Provide at least one trusted CIDR; unrestricted 0.0.0.0/0 access is prohibited."
  }
}

variable "node_instance_types" {
  description = "EC2 instance types available to the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of EKS worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of EKS worker nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of EKS worker nodes."
  type        = number
  default     = 3
}
