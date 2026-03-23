# Bootstrap: create the Terraform remote state bucket.
#
# This must be applied once before any other Terraform module in this repo,
# because every other module uses this bucket as its S3 backend.
#
# Authentication: set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY to your
# Hetzner Object Storage access key and secret before running.

module "state_bucket" {
  source = "../../modules/shared/storage"

  bucket_name = var.bucket_name
  region      = var.region
  endpoint    = var.endpoint
}
