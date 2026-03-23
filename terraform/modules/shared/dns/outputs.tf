output "zone_id" {
  value       = data.cloudflare_zone.zone.id
  description = "Cloudflare zone ID for the managed domain. Pass to cloudflare_record resources to create DNS entries for platform services."
}

output "nameservers" {
  value       = data.cloudflare_zone.zone.name_servers
  description = "Cloudflare nameservers assigned to this zone."
}
