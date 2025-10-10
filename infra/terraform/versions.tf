terraform {
  required_version = ">= 1.13, < 2.0"

  required_providers {
    hcloud    = { source = "hetznercloud/hcloud", version = "~> 1.54" }
    random    = { source = "hashicorp/random",     version = "~> 3.7" }
    cloudinit = { source = "hashicorp/cloudinit",  version = "~> 2.3" }
  }
}
