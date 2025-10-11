#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="default"
APP="items-service"
HOST="items.5.78.158.102.sslip.io"
STAGING_ISSUER="letsencrypt-staging"
PROD_ISSUER="letsencrypt-prod"
CERT_NAME="items-service-tls"

echo "==> Ensure cert-manager is installed"
if ! kubectl get ns cert-manager >/dev/null 2>&1; then
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.0/cert-manager.yaml
fi

echo "==> Wait for cert-manager deployments to be ready"
kubectl -n cert-manager rollout status deploy/cert-manager --timeout=3m
kubectl -n cert-manager rollout status deploy/cert-manager-webhook --timeout=3m
kubectl -n cert-manager rollout status deploy/cert-manager-cainjector --timeout=3m

echo "==> Apply ClusterIssuers (staging + prod)"
kubectl apply -f k8s/issuers/clusterissuer-staging.yaml
kubectl apply -f k8s/issuers/clusterissuer-prod.yaml

echo "==> Point ingress to STAGING for first issuance"
if kubectl -n "$NAMESPACE" get ingress "$APP" >/dev/null 2>&1; then
  kubectl -n "$NAMESPACE" annotate ingress "$APP" cert-manager.io/cluster-issuer="$STAGING_ISSUER" --overwrite
else
  echo "ERROR: Ingress $APP not found in namespace $NAMESPACE. Apply your app manifest first."
  exit 1
fi

echo "==> Wait for staging Certificate to be Ready"
for i in {1..30}; do
  if kubectl -n "$NAMESPACE" get certificate "$CERT_NAME" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
kubectl -n "$NAMESPACE" wait certificate/"$CERT_NAME" --for=condition=Ready=true --timeout=10m

echo "==> Promote to PROD issuer and re-issue cert"
kubectl -n "$NAMESPACE" annotate ingress "$APP" cert-manager.io/cluster-issuer="$PROD_ISSUER" --overwrite
kubectl -n "$NAMESPACE" delete certificate "$CERT_NAME" --ignore-not-found

for i in {1..30}; do
  if kubectl -n "$NAMESPACE" get certificate "$CERT_NAME" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
kubectl -n "$NAMESPACE" wait certificate/"$CERT_NAME" --for=condition=Ready=true --timeout=10m

echo "==> Done. Validate:"
echo "    curl -I https://$HOST"
