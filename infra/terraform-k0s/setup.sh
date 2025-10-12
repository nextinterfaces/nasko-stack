
#!/usr/bin/env bash
set -euo pipefail

# Log all output
exec > >(tee -a /root/bootstrap.log) 2>&1

# Ensure basic deps
apt-get update -y || true
apt-get install -y curl wget ca-certificates gnupg lsb-release jq apt-transport-https

# k0s
curl -sSLf https://get.k0s.sh | sh
k0s install controller --single
systemctl enable k0scontroller
systemctl start k0scontroller

mkdir -p /root/.kube
for i in {1..60}; do
  if k0s kubeconfig admin > /root/.kube/config; then break; fi
  sleep 5
done
chmod 600 /root/.kube/config

# kubectl wrapper + alias
cat >/usr/local/bin/kubectl <<'EOF'
#!/usr/bin/env bash
exec k0s kubectl "$@"
EOF
chmod +x /usr/local/bin/kubectl
echo "alias k=kubectl" >/etc/profile.d/alias-k.sh

# Helm
curl -sSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Wait for API
for i in {1..60}; do
  if kubectl get nodes; then break; fi
  sleep 5
done

# ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx

# cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.crds.yaml
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install cert-manager jetstack/cert-manager -n cert-manager --set installCRDs=false

# ClusterIssuer
cat >/root/cluster-issuer.yaml <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    email: "${letsencrypt_email}"
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-account-key
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
kubectl apply -f /root/cluster-issuer.yaml

# sslip.io helper
cat >/usr/local/bin/sslip-hostname <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if ip=$(curl -s --connect-timeout 2 http://169.254.169.254/hetzner/v1/metadata | jq -r '.public_ipv4.ip // empty'); then
  if [[ -n "$ip" && "$ip" != "null" ]]; then
    echo "${ip}.sslip.io"
    exit 0
  fi
fi
ip=$(curl -s https://api.ipify.org)
echo "${ip}.sslip.io"
EOF
chmod +x /usr/local/bin/sslip-hostname

echo "Bootstrap complete. Hostname: $(/usr/local/bin/sslip-hostname)"
