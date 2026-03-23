variable "bucket_name" {
  type        = string
  default     = "terraform-state-ai-infra"
  description = "Name of the Terraform state bucket to create. Must be globally unique within Hetzner Object Storage."
}

variable "region" {
  type        = string
  default     = "eu-central-1"
  description = "Hetzner Object Storage region. eu-central-1 maps to fsn1 (Falkenstein)."
}

variable "endpoint" {
  type        = string
  default     = "https://fsn1.your-objectstorage.com"
  description = "Hetzner Object Storage S3-compatible endpoint URL."
}
