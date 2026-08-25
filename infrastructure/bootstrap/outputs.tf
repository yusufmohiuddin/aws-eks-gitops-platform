output "state_bucket_name" {
  description = "S3 bucket used by Terraform environment backends."
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state bucket."
  value       = aws_s3_bucket.terraform_state.arn
}

output "backend_configuration" {
  description = "Non-secret partial backend configuration for this bootstrap stack."
  value = {
    bucket       = aws_s3_bucket.terraform_state.id
    key          = "bootstrap/terraform.tfstate"
    region       = var.aws_region
    encrypt      = true
    use_lockfile = true
  }
}
