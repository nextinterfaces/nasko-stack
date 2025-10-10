output "server_public_ip" {
  value = hcloud_server.k3s.ipv4_address
}

output "ssh_command" {
  value = "ssh -i ${var.ssh_private_key_path} root@${hcloud_server.k3s.ipv4_address}"
}

output "kubeconfig_pull_cmd" {
  value = "scp -i ${var.ssh_private_key_path} ubuntu@${hcloud_server.k3s.ipv4_address}:/etc/rancher/k3s/k3s.yaml ./k3s.yaml && KUBECONFIG=./k3s.yaml kubectl get nodes"
}
