variable "project" {
  description = "Project name"
  type        = string
  default     = "nasko-stack"
}

# If set, we reuse this key from Hetzner (no new key is created)
variable "existing_ssh_key_name" {
  description = "Name of an existing SSH key in Hetzner to reuse (optional)."
  type        = string
  default     = ""
}

# If existing_ssh_key_name is empty, we will read this public key file and create/use it
variable "ssh_public_key_path" {
  description = "Path to the SSH public key file (env TF_VAR_ssh_public_key_path). Ignored if existing_ssh_key_name is set."
  type        = string
  default     = ""
}

# Not used by Terraform providers; only used to craft SSH/SCP commands in outputs
variable "ssh_private_key_path" {
  description = "Path to the SSH private key (local; used in outputs to form SSH/SCP commands)."
  type        = string
  default     = "~/.ssh/id_ed25519_hetzner"
}

variable "server_type" {
  description = "Hetzner server type"
  type        = string
  default     = "cpx11"
}

variable "location" {
  description = "Hetzner location (e.g., hil)"
  type        = string
  default     = "hil"
}

variable "image" {
  description = "Image slug"
  type        = string
  default     = "ubuntu-24.04"
}

