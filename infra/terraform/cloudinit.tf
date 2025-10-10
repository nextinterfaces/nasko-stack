data "cloudinit_config" "k3s" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-init.yaml"
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/cloud-init.tftpl", {
      ssh_pubkey = trimspace(file(var.ssh_public_key_path))
    })
  }
}
