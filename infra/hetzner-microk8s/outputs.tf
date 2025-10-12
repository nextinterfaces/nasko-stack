output "server_ip" {
  value = hcloud_server.microk8s.ipv4_address
}

output "access_url" {
  value = "https://${hcloud_server.microk8s.ipv4_address}.nip.io/test"
}

output "ssh_command" {
  value = "ssh ubuntu@${hcloud_server.microk8s.ipv4_address}"
}

