variable "bucket_name" {
  type        = string
  description = "Name of the S3-compatible object storage bucket. Must be globally unique for the chosen provider."
}

variable "region" {
  type        = string
  default     = "eu-central-1"
  description = "Storage region. For Hetzner Object Storage use eu-central-1 (maps to fsn1) or us-east-1 (maps to ash)."
}

variable "endpoint" {
  type        = string
  default     = "https://fsn1.your-objectstorage.com"
  description = "S3-compatible endpoint URL. Defaults to Hetzner Object Storage (Falkenstein). Override for other regions or providers."
}
