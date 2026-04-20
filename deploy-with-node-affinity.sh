#!/bin/bash

echo "========================================="
echo "🚀 Deploying with Node Affinity"
echo "========================================="

# Deploy Backend to Worker 1 (backend node)
helm upgrade --install ecommerce-backend ./helm/backend \
  --namespace ecommerce-dev \
  --create-namespace \
  --values ./helm/backend/values-dev.yaml \
  --set image.repository=zahidbilal/ecommerce-backend \
  --set image.tag=latest \
  --set image.pullPolicy=Always \
  --set nodeSelector."workload"=backend \
  --set affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key=workload \
  --set affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator=In \
  --set affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values={backend} \
  --wait

# Deploy Frontend to Worker 2 (frontend node)
helm upgrade --install ecommerce-frontend ./helm/frontend \
  --namespace ecommerce-dev \
  --set image.repository=zahidbilal/ecommerce-frontend \
  --set image.tag=latest \
  --set nodeSelector."workload"=frontend \
  --set service.type=NodePort \
  --set service.nodePort=30081 \
  --wait

# Deploy MongoDB to Worker 3 (database node)
helm upgrade --install ecommerce-backend-mongodb bitnami/mongodb \
  --namespace ecommerce-dev \
  --set architecture=standalone \
  --set auth.enabled=true \
  --set auth.rootPassword=root123 \
  --set auth.database=ecommerce \
  --set nodeSelector."workload"=database \
  --set persistence.enabled=false \
  --wait

echo "✅ All workloads deployed to dedicated nodes!"
echo ""
echo "Node distribution:"
kubectl get pods -n ecommerce-dev -o wide
