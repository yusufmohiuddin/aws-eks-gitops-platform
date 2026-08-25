variable "aws_region" {
  description = "AWS Region that stores the Terraform state."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-gov)?-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS Region name."
  }
}

variable "project_name" {
  description = "Stable project identifier used in resource names and tags."
  type        = string
  default     = "aws-eks-gitops-platform"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$", var.project_name))
    error_message = "project_name must contain 3-40 lowercase letters, numbers, or hyphens."
  }
}

variable "additional_tags" {
  description = "Additional tags merged with the required platform tags."
  type        = map(string)
  default     = {}
}
