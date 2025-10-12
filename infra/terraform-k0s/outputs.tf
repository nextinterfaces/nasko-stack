
output "server_ipv4" {
  description = "Public IPv4 of the k0s server"
  value       = hcloud_server.k0s.ipv4_address
}

output "server_name" {
  value = hcloud_server.k0s.name
}

output "sslip_hostname" {
  description = "Public hostname using sslip.io"
  value       = "${hcloud_server.k0s.ipv4_address}.sslip.io"
}
