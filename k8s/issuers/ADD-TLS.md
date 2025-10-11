# TLS Automation

This guide automates your TLS bootstrap for **items-service** on **k3s/Traefik** using **cert-manager + Let’s Encrypt** — all from your terminal.

- **Host:** `items.5.78.158.102.sslip.io`
- **Namespace:** `default`
- **App/Ingress name:** `items-service`
- **Certificate secret:** `items-service-tls`

## Prerequisites
- `kubectl` points at your Hetzner k3s cluster:
  ```bash
  kubectl cluster-info
  kubectl get nodes
  ```
- Ports **80/443** open on Hetzner firewall and OS firewall.
- Traefik is your ingress controller (default in k3s).

## Files used
- `scripts/tls_bootstrap.sh` — does the full staging→prod issuance
- `k8s/issuers/clusterissuer-staging.yaml`
- `k8s/issuers/clusterissuer-prod.yaml`
- `k8s/items-service.prod.yaml` — (optional) app + Ingress set to **letsencrypt-prod** for ongoing use

> The script will **install cert-manager if missing**, create Issuers, issue a staging cert, then promote to production automatically.

## 1) Ensure your app/ingress exists
If you don’t already have the app & Ingress applied, use the provided manifest (or your own):
```bash
kubectl apply -f k8s/items-service.prod.yaml
```

Requirements if using your own Ingress:
- `metadata.name: items-service`
- `spec.ingressClassName: traefik` (or `kubernetes.io/ingress.class: traefik`)
- Host: `items.5.78.158.102.sslip.io`
- `tls.secretName: items-service-tls`

## 2) Run the local bootstrap
```bash
bash scripts/tls_bootstrap.sh
```
What it does:
1. Installs **cert-manager** (if not present)
2. Applies **letsencrypt-staging** and **letsencrypt-prod** ClusterIssuers
3. Points your Ingress to **staging**, waits for `Certificate items-service-tls` **Ready**
4. Switches to **prod** and re-issues, then waits for **Ready**

You can safely re-run the script; it’s idempotent.

## 3) Verify
```bash
kubectl -n default get certificate items-service-tls -o wide
kubectl -n default get secret items-service-tls
curl -I https://items.5.78.158.102.sslip.io
```
You should now see a **valid Let’s Encrypt production certificate**.

## Troubleshooting
- **Issuer not Ready**: `kubectl get clusterissuer`, then `kubectl describe clusterissuer letsencrypt-prod`
- **Challenges stuck**:
  ```bash
  kubectl get order,challenge -A
  kubectl describe challenge -n default <challenge-name>
  kubectl -n cert-manager logs deploy/cert-manager --tail=200 -f
  ```
- **HTTP-01 fails**: confirm ports 80/443 are open; host resolves to your node IP; Ingress uses the Traefik class; no conflicting Ingress rules.
- **Still serving staging cert**: ensure the Ingress annotation is `cert-manager.io/cluster-issuer: letsencrypt-prod`, then
  ```bash
  kubectl -n default delete certificate items-service-tls
  kubectl apply -f k8s/items-service.prod.yaml
  ```

## Ongoing use
- Keep `letsencrypt-prod` on your Ingress.
- cert-manager will automatically **renew** before expiry — no action needed.
- If you change the hostname, update the Ingress `spec.rules[].host` and `tls.hosts[]`, then `kubectl apply -f ...`.

## Clean up (optional)
```bash
# Remove staging issuer (after promotion)
kubectl delete clusterissuer letsencrypt-staging || true
```
