variable "ssh_public_key_path" {
  description = "Path to your SSH public key file (set via env TF_VAR_ssh_public_key_path)"
  type        = string
}

variable "server_type" {
  description = "Hetzner server type"
  type        = string
  default     = "cpx11"
}

variable "location" {
  description = "Hetzner location (e.g., fsn1, nbg1, hel1, ash, hil)"
  type        = string
  default     = "hil"   # US-West (Hillsboro)
}

variable "image" {
  description = "Image slug"
  type        = string
  default     = "ubuntu-24.04"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "nasko-stack"
}

