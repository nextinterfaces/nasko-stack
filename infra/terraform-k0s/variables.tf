
variable "ssh_pubkey_path" {
  description = "Path to your local SSH public key (e.g., ~/.ssh/id_rsa.pub)"
  type        = string
}

variable "letsencrypt_email" {
  description = "Email address to register with Let's Encrypt (for cert-manager ClusterIssuer)"
  type        = string
}

variable "server_type" {
  description = "Hetzner server type"
  type        = string
  default     = "cx22"
}

variable "location" {
  description = "Hetzner location (Germany)"
  type        = string
  default     = "nbg1"
}

variable "image" {
  description = "Base image to use"
  type        = string
  default     = "ubuntu-22.04"
}
