terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
  required_version = ">= 1.5.0"
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "default" {
  name       = "hetzner-key"
  public_key = file(var.ssh_public_key_path)
}

resource "hcloud_server" "microk8s" {
  name        = "microk8s-node"
  server_type = "cx11"
  image       = "ubuntu-22.04"
  location    = "ash" # Hetzner US-West (Ashburn)
  ssh_keys    = [hcloud_ssh_key.default.id]
  user_data   = file("cloud-init.yaml")

  firewall_ids = [hcloud_firewall.k8s.id]
}

resource "hcloud_firewall" "k8s" {
  name = "k8s-fw"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

output "server_ip" {
  value = hcloud_server.microk8s.ipv4_address
}

output "access_url" {
  value = "https://${hcloud_server.microk8s.ipv4_address}.nip.io/test"
}

