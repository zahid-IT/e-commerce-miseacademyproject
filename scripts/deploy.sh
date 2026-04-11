#!/bin/bash

ENVIRONMENT=$1
if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: ./deploy.sh <dev|staging|production>"
    exit 1
fi

echo "Deploying to $ENVIRONMENT environment..."

# Build images
docker build -t ecommerce-backend:$ENVIRONMENT ./backend
docker build -t ecommerce-frontend:$ENVIRONMENT ./frontend

# Tag and push
docker tag ecommerce-backend:$ENVIRONMENT your-registry/ecommerce-backend:$ENVIRONMENT-latest
docker push your-registry/ecommerce-backend:$ENVIRONMENT-latest

# Deploy with Helm
helm upgrade --install ecommerce-backend ./helm/backend \
    --namespace ecommerce-$ENVIRONMENT \
    --create-namespace \
    -f ./helm/backend/values-$ENVIRONMENT.yaml

helm upgrade --install ecommerce-frontend ./helm/frontend \
    --namespace ecommerce-$ENVIRONMENT \
    -f ./helm/frontend/values-$ENVIRONMENT.yaml

echo "Deployment to $ENVIRONMENT completed!"
