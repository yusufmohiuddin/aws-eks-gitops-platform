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
