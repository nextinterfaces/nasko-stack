provider "hcloud" {}

locals {
  # version-agnostic sanitization for hostnames
  safe_project = replace(replace(lower(var.project), "_", "-"), " ", "-")

  labels = {
    project    = var.project
    managed_by = "terraform"
  }
}

# Random suffix used to avoid account-level name collisions (firewall, server, key)
resource "random_id" "suffix" {
  byte_length = 2
}

# Firewall: name includes suffix to avoid "name is already used"
resource "hcloud_firewall" "base" {
  name   = "${local.safe_project}-fw-${random_id.suffix.hex}"
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

# Option A: reuse an existing key by name (if provided)
data "hcloud_ssh_key" "existing" {
  count = var.existing_ssh_key_name != "" ? 1 : 0
  name  = var.existing_ssh_key_name
}

# Option B: create a new key from the given file (if no existing key name provided)
resource "hcloud_ssh_key" "me" {
  count      = var.existing_ssh_key_name == "" ? 1 : 0
  name       = "${local.safe_project}-ssh-${random_id.suffix.hex}"
  public_key = file(var.ssh_public_key_path)
  labels     = local.labels

  lifecycle {
    create_before_destroy = true
  }
}

# k3s server (uses the chosen SSH key)
resource "hcloud_server" "k3s" {
  name        = "${local.safe_project}-${random_id.suffix.hex}"
  server_type = var.server_type
  image       = var.image
  location    = var.location

  # IMPORTANT: keep this as a single expression
  ssh_keys = var.existing_ssh_key_name != "" ? [data.hcloud_ssh_key.existing[0].id] : [hcloud_ssh_key.me[0].id]

  firewall_ids = [hcloud_firewall.base.id]
  labels       = local.labels

  user_data = data.cloudinit_config.k3s.rendered
}
