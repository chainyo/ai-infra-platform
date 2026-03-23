# terraform/modules/shared/storage

Provisions an S3-compatible object storage bucket for platform data. Used by Loki (log retention) and Velero (cluster backups).

**Scope**: Apply once per account, not per cluster. A single bucket serves multiple cluster environments using different key prefixes.

---

## Authentication

Set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in your environment before running any Terraform commands. The AWS provider reads them automatically — no credentials go in `.tfvars` files.

```bash
# Hetzner Object Storage credentials (found in Hetzner Cloud console → Object Storage → Manage Credentials)
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
```

---

## Quick start

```bash
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"

terraform init
terraform apply \
  -var="bucket_name=ai-infra-platform-storage" \
  -var="endpoint=https://fsn1.your-objectstorage.com"

# Get outputs for Loki and Velero configuration
terraform output bucket_name
terraform output endpoint
```

---

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `bucket_name` | `string` | required | Name of the S3-compatible bucket. Must be globally unique for the chosen provider. |
| `region` | `string` | `eu-central-1` | Storage region. For Hetzner Object Storage: `eu-central-1` (fsn1) or `us-east-1` (ash). |
| `endpoint` | `string` | `https://fsn1.your-objectstorage.com` | S3-compatible endpoint URL. Set to your provider's endpoint for the chosen region. |

### Hetzner Object Storage endpoints

| Region | Endpoint |
|--------|----------|
| Falkenstein (fsn1) | `https://fsn1.your-objectstorage.com` |
| Nuremberg (nbg1) | `https://nbg1.your-objectstorage.com` |
| Helsinki (hel1) | `https://hel1.your-objectstorage.com` |
| Ashburn (ash) | `https://ash.your-objectstorage.com` |

---

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `bucket_name` | `string` | Name of the provisioned bucket. Pass to Loki `storageConfig` and Velero `backupStorageLocation`. |
| `endpoint` | `string` | S3-compatible endpoint URL. Pass alongside `bucket_name` to Loki and Velero. |

---

## Downstream configuration examples

**Loki (values.yaml)**:
```yaml
loki:
  storage:
    type: s3
    s3:
      endpoint: <endpoint output>
      bucketnames: <bucket_name output>
      region: eu-central-1
      accessKeyId: ${AWS_ACCESS_KEY_ID}
      secretAccessKey: ${AWS_SECRET_ACCESS_KEY}
```

**Velero (BackupStorageLocation)**:
```yaml
apiVersion: velero.io/v1
kind: BackupStorageLocation
spec:
  provider: aws
  objectStorage:
    bucket: <bucket_name output>
  config:
    region: eu-central-1
    s3Url: <endpoint output>
    s3ForcePathStyle: "true"
```

---

## Notes

- Versioning is enabled by default. This protects against accidental deletion of log data and backup archives.
- The AWS provider is used with `skip_credentials_validation = true` because Hetzner Object Storage does not expose the AWS STS endpoints used for credential validation.
- This module is not AWS-specific — any S3-compatible storage provider works by overriding `var.endpoint`.
