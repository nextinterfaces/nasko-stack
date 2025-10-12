apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo
  namespace: demo
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - api.${PUBLIC_IP}.sslip.io
      secretName: echo-tls
  rules:
    - host: api.${PUBLIC_IP}.sslip.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: echo
                port:
                  number: 80
