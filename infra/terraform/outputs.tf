output "server_public_ip" {
  value = hcloud_server.k3s.ipv4_address
}

output "ssh_command" {
  value = "ssh ubuntu@${hcloud_server.k3s.ipv4_address}"
}

output "kubeconfig_pull_cmd" {
  value = "scp ubuntu@${hcloud_server.k3s.ipv4_address}:/etc/rancher/k3s/k3s.yaml ./k3s.yaml && KUBECONFIG=./k3s.yaml kubectl get nodes"
}
