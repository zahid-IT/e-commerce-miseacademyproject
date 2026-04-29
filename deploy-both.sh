cat > ~/deploy-both.sh << 'EOF'
#!/bin/bash

set -e

echo "========================================="
echo "🚀 Deploying Backend and Frontend"
echo "========================================="

cd ~/e-commerce-miseacademyproject

# Fix ingress template
echo "Fixing ingress template..."
cat > helm/frontend/templates/ingress.yaml << 'INGEOF'
{{- if .Values.ingress.enabled }}
{{- $fullName := include "frontend.fullname" . -}}
{{- $svcPort := .Values.service.port -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $fullName }}
  labels:
    {{- include "frontend.labels" . | nindent 4 }}
  annotations:
    {{- with .Values.ingress.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  {{- if .Values.ingress.className }}
  ingressClassName: {{ .Values.ingress.className }}
  {{- end }}
  {{- if .Values.ingress.tls }}
  tls:
    {{- range .Values.ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ $fullName }}
                port:
                  number: {{ $svcPort }}
          {{- end }}
    {{- end }}
{{- end }}
INGEOF

# Update frontend values (disable ingress)
cat > helm/frontend/values.yaml << 'VALEOF'
replicaCount: 1

image:
  repository: zahidbilal/ecommerce-frontend
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: NodePort
  port: 80
  targetPort: 80
  nodePort: 30081

ingress:
  enabled: false

config:
  apiUrl: "http://ecommerce-backend.backend:3000/api"
  environment: development
  enableAnalytics: "false"
  enableDebugTools: "true"

resources:
  requests:
    memory: 128Mi
    cpu: 100m
  limits:
    memory: 256Mi
    cpu: 200m

livenessProbe:
  enabled: true
  path: /
  initialDelaySeconds: 15

readinessProbe:
  enabled: true
  path: /
  initialDelaySeconds: 5

autoscaling:
  enabled: false

monitoring:
  enabled: false
VALEOF

# Create namespaces
echo "Creating namespaces..."
kubectl create namespace backend --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace frontend --dry-run=client -o yaml | kubectl apply -f -

# Deploy backend
echo "Deploying backend..."
helm upgrade --install ecommerce-backend ./helm/backend \
  --namespace backend \
  -f ./helm/backend/values-dev.yaml \
  --wait \
  --timeout 10m

# Deploy frontend
echo "Deploying frontend..."
helm upgrade --install ecommerce-frontend ./helm/frontend \
  --namespace frontend \
  -f ./helm/frontend/values.yaml \
  --wait \
  --timeout 5m

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "Check status:"
kubectl get pods -n backend
kubectl get pods -n frontend
echo ""
echo "Services:"
kubectl get svc -n backend
kubectl get svc -n frontend

# Get IP
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    IP=$(minikube ip)
else
    IP="localhost"
fi

echo ""
echo "Access URLs:"
echo "  Backend: http://$IP:30080"
echo "  Frontend: http://$IP:30081"
EOF

