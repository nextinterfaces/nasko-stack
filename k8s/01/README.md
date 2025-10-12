# k0s on Hetzner: nginx-ingress + cert-manager (Let's Encrypt) + sample REST (sslip.io)

This project sets up:
- **ingress-nginx** as your Ingress controller
- **cert-manager** with a production **ClusterIssuer** using your email: `nextinterfaces@gmail.com`
- A **sample REST server** (Echo server) exposed at **api.<PUBLIC_IP>.sslip.io**
- Ingress with automatic Let's Encrypt TLS via `sslip.io` (no domain needed)

> **Prereqs**: `kubectl` (connected to your k0s cluster) and **Helm v3** installed on your machine.

---

## 1) Install ingress-nginx and cert-manager

```bash
bash scripts/install_ingress_and_certmanager.sh
```

This will:
- Install **ingress-nginx** in namespace `ingress-nginx`
- Install **cert-manager** (including CRDs) in namespace `cert-manager`

Wait until all Pods in both namespaces are **READY**:
```bash
kubectl get pods -n ingress-nginx
kubectl get pods -n cert-manager
```

> On Hetzner, make sure your cluster exposes **ingress-nginx-controller** publicly (via a LoadBalancer or a routable node IP/hostPort). You need a public IP that routes to the controller for HTTP-01 challenges and traffic.

---

## 2) Create the ClusterIssuer

```bash
kubectl apply -f k8s/cluster-issuer.yaml
```

This creates a production **ClusterIssuer** named `letsencrypt-prod` that uses your email.

---

## 3) Deploy the sample REST server

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/echo-deployment.yaml
kubectl apply -f k8s/echo-service.yaml
```

This deploys a JSON echo server in namespace `demo`.

---

## 4) Configure your PUBLIC IP and apply the Ingress

Set `PUBLIC_IP` to the **public IPv4** that points to your **ingress-nginx** (LoadBalancer or node public IP). The host will be `api.${PUBLIC_IP}.sslip.io`.

### Option A: Let the script auto-detect the IP (tries LB first)
```bash
bash scripts/set_ip_and_apply.sh
```

### Option B: Provide the IP explicitly
```bash
bash scripts/set_ip_and_apply.sh 203.0.113.42
# or
PUBLIC_IP=203.0.113.42 bash scripts/set_ip_and_apply.sh
```

This will render `k8s/_rendered/ingress.yaml` and apply it.

---

## 5) Verify

```bash
kubectl get ingress -n demo
# wait for ADDRESS column to show an IP/hostname

# Watch certificate status
kubectl describe certificate echo-cert -n demo
kubectl get certificate -n demo
kubectl get secret echo-tls -n demo
```

Once the certificate is **Ready**, open:
```
https://api.<PUBLIC_IP>.sslip.io/
```

You should see the echo server JSON response over HTTPS.

---

## Troubleshooting

- **No external IP on ingress-nginx-controller**  
  Ensure your Hetzner setup provides a reachable public IP (via LoadBalancer, or hostNetwork/hostPort + firewall rules).

- **HTTP-01 challenge fails**  
  Port **80** must reach the ingress controller. Temporarily allow port 80 if you lock down firewalls. cert-manager uses HTTP-01 to validate ownership.

- **Email change**  
  To use a different Let's Encrypt email, edit `k8s/cluster-issuer.yaml` and re-apply.

- **Swap sample app**  
  Replace `ealen/echo-server:latest` with your own image in `k8s/echo-deployment.yaml` (port 80), then restart the Deployment.

---

**Enjoy!**
