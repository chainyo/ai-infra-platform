# terraform/modules/shared/dns

Manages a Cloudflare DNS zone. Outputs the zone ID consumed by other modules and bootstrap scripts to create DNS records for platform services.

**Scope**: Apply once per account/domain, not per cluster. A single DNS zone serves all cluster environments.

---

## Authentication

Set `CLOUDFLARE_API_TOKEN` in your environment before running any Terraform commands. The Cloudflare provider reads it automatically — no credentials go in `.tfvars` files.

```bash
export CLOUDFLARE_API_TOKEN="your_cloudflare_api_token"
```

You can create a token at [dash.cloudflare.com](https://dash.cloudflare.com) → Profile → API Tokens. The token needs **Zone:Read** permissions at minimum.

**Prerequisite**: The domain must already exist as a zone in your Cloudflare account. This module does not register domains — it reads the existing zone to expose its ID.

---

## Quick start

```bash
export CLOUDFLARE_API_TOKEN="your_token"

terraform init
terraform apply -var="domain=example.com"

# Get the zone ID for use in other modules
terraform output zone_id
```

---

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `domain` | `string` | required | The domain name managed in Cloudflare (e.g. `example.com`). The zone must already exist in your account. |

---

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `zone_id` | `string` | Cloudflare zone ID. Pass to `cloudflare_record` resources to create DNS entries for platform services (ingress, ArgoCD, Grafana, etc.). |
| `nameservers` | `list(string)` | Cloudflare nameservers assigned to the zone. Configure these at your domain registrar. |

---

## How it works

This module uses a `cloudflare_zone` data source — it reads the existing zone from the Cloudflare API and surfaces its ID. No resources are created or destroyed; `terraform destroy` has no effect on the DNS zone itself.

---

## Limitations

- Cloudflare is the only supported DNS provider in this module. For AWS Route 53 or GCP Cloud DNS, a separate module would be needed.
- The zone must be activated in Cloudflare (nameservers delegated at your registrar) before platform services can resolve.
