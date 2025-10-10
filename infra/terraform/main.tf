provider "hcloud" {}

locals {
  # version-agnostic hostname sanitization
  safe_project = replace(replace(lower(var.project), "_", "-"), " ", "-")

  labels = {
    project    = var.project
    managed_by = "terraform"
  }

  # decide key mode: "existing" (by name) or "file" (path) or "unset"
  key_mode = var.existing_ssh_key_name != "" ? "existing" : (var.ssh_public_key_path != "" ? "file" : "unset")
}

# suffix to avoid account-level name collisions
resource "random_id" "suffix" {
  byte_length = 2
}

# ---------- Firewall (MULTI-LINE RULES) ----------
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

# ---------- SSH key selection ----------
# Option A: reuse existing key by name
data "hcloud_ssh_key" "existing" {
  count = local.key_mode == "existing" ? 1 : 0
  name  = var.existing_ssh_key_name
}

# Option B: create from public key file
resource "hcloud_ssh_key" "me" {
  count      = local.key_mode == "file" ? 1 : 0
  name       = "${local.safe_project}-ssh-${random_id.suffix.hex}"
  public_key = file(var.ssh_public_key_path)
  labels     = local.labels

  lifecycle {
    create_before_destroy = true
  }
}

# ---------- Server with k3s ----------
resource "hcloud_server" "k3s" {
  name        = "${local.safe_project}-${random_id.suffix.hex}"
  server_type = var.server_type
  image       = var.image
  location    = var.location

  # keep this ternary on a single expression line
  ssh_keys = local.key_mode == "existing" ? [data.hcloud_ssh_key.existing[0].id] : [hcloud_ssh_key.me[0].id]

  firewall_ids = [hcloud_firewall.base.id]
  labels       = local.labels

  user_data = data.cloudinit_config.k3s.rendered

  # fail fast if neither key input was provided
  lifecycle {
    precondition {
      condition     = local.key_mode != "unset"
      error_message = "Provide either TF_VAR_existing_ssh_key_name or TF_VAR_ssh_public_key_path."
    }
  }
}
