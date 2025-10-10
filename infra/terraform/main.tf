provider "hcloud" {}

locals {
  # Simple sanitization: lowercase, replace underscores and spaces with dashes
  safe_project = replace(replace(lower(var.project), "_", "-"), " ", "-")

  labels = {
    project    = var.project
    managed_by = "terraform"
  }
}

# --- Firewall: SSH, K8s API, HTTP/HTTPS ---
resource "hcloud_firewall" "base" {
  name   = "${local.safe_project}-fw"
  labels = local.labels

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
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
}

# --- SSH key ---
resource "hcloud_ssh_key" "me" {
  name       = "${local.safe_project}-ssh"
  public_key = file(var.ssh_public_key_path)
  labels     = local.labels
}

# --- Random suffix for uniqueness ---
resource "random_id" "suffix" {
  byte_length = 2
}

# --- k3s server ---
resource "hcloud_server" "k3s" {
  name         = "${local.safe_project}-${random_id.suffix.hex}"
  server_type  = var.server_type
  image        = var.image
  location     = var.location

  ssh_keys     = [hcloud_ssh_key.me.id]
  firewall_ids = [hcloud_firewall.base.id]
  labels       = local.labels

  user_data = data.cloudinit_config.k3s.rendered
}

