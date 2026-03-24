output "kubeconfig" {
  value=   data.external.kubeconfig.result["kubeconfig"]
  description = "kubeconfig for the provisioned k3s cluster. Use with kubectl and helm. Pass to bootstrap-cluster.sh for GitOps bootstrap."
  sensitive   = true
}

output "server_ip" {
  value       = hcloud_server.k3s.ipv4_address
  description = "Public IPv4 address of the k3s server."
}

output "server_id" {
  value       = hcloud_server.k3s.id
  description = "Hetzner Cloud server ID."
}
