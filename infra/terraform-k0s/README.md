
# Hetzner k0s Single-Node Cluster (Terraform) — sslip.io

Provisions **CX11** in **Germany (default nbg1)** and bootstraps **k0s** with **nginx-ingress** and **cert-manager**.
No domain required — it automatically uses **sslip.io** based on the server's public IP.

## Environment Variables
```bash
export HCLOUD_TOKEN="your-hetzner-api-token"
export TF_VAR_letsencrypt_email="you@example.com"
export TF_VAR_ssh_pubkey_path="$HOME/.ssh/id_rsa.pub"
```

## Usage
```bash
terraform init
terraform apply -auto-approve
```

After apply:
- Public IP: `terraform output -raw server_ipv4`
- sslip hostname: `terraform output -raw sslip_hostname` (e.g., `1.2.3.4.sslip.io`)
- SSH: `ssh root@$(terraform output -raw server_ipv4)` then `k get nodes`

Notes:
- `kubectl` is provided via `k0s kubectl` wrapper; alias `k` is added.
- cert-manager has a `ClusterIssuer` named `letsencrypt`.
- Ports 22/80/443 are open via Firewall.
- On the server, `/usr/local/bin/sslip-hostname` prints the computed sslip host.


### Instance type notes
- Default `server_type` is **cax11** (ARM, cheapest).
- If you prefer x86/AMD, set `-var 'server_type=cpx11'` on apply or change the default in `variables.tf`.
- Both are widely available in Germany locations.


## Provisioner fallback (if cloud-init is skipped)
This project now ships a **remote-exec** fallback that connects over SSH as `root` and installs everything.
Make sure your matching **private key** is accessible, or override:
```bash
terraform apply -auto-approve -var 'ssh_private_key_path=~/.ssh/id_ed25519'
```
After provisioning, reconnect (new shell) so the `k` alias loads from `/etc/profile.d/alias-k.sh`.
