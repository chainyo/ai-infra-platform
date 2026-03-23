output "bucket_name" {
  value       = aws_s3_bucket.storage.id
  description = "Name of the provisioned S3-compatible bucket. Pass to Loki and Velero configuration as the storage backend."
}

output "endpoint" {
  value       = var.endpoint
  description = "S3-compatible endpoint URL for the storage bucket. Pass to Loki and Velero configuration alongside the bucket name."
}
