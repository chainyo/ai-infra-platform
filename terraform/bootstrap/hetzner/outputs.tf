output "bucket_name" {
  value       = module.state_bucket.bucket_name
  description = "Name of the provisioned Terraform state bucket."
}

output "endpoint" {
  value       = module.state_bucket.endpoint
  description = "S3-compatible endpoint URL for the state bucket."
}
