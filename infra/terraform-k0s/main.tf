
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.47.0"
    }
  }
}

provider "hcloud" {
  # Picks up HCLOUD_TOKEN from env
}

resource "hcloud_ssh_key" "me" {
  name       = "k0s-key"
  public_key = file(var.ssh_pubkey_path)
}

resource "hcloud_firewall" "k0s_fw" {
  name = "k0s-basic"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "out"
    protocol   = "icmp"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "out"
    protocol   = "tcp"
    port       = "1-65535"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "out"
    protocol   = "udp"
    port       = "1-65535"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_server" "k0s" {
  name        = "k0s-single"
  server_type = var.server_type
  image       = var.image
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.me.id]
  firewall_ids = [hcloud_firewall.k0s_fw.id]

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    letsencrypt_email = var.letsencrypt_email
  })


provisioner "file" {
  source      = "${path.module}/setup.sh"
  destination = "/root/setup.sh"

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
    host        = self.ipv4_address
  }
}

provisioner "remote-exec" {
  inline = [
    "chmod +x /root/setup.sh",
    "LETSE=${var.letsencrypt_email} bash -lc 'letsencrypt_email=${var.letsencrypt_email} /root/setup.sh'"
  ]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
    host        = self.ipv4_address
  }
}

}
