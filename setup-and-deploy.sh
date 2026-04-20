#!/bin/bash

# Run the complete setup
./setup-kind-complete.sh

# After setup completes, deploy your app
echo "Starting application deployment..."

# Load images to KIND
echo "Loading images to KIND..."
docker build -t zahidbilal/ecommerce-backend:latest ./backend
docker build -t zahidbilal/ecommerce-frontend:latest ./frontend

kind load docker-image zahidbilal/ecommerce-backend:latest --name ecommerce-cluster
kind load docker-image zahidbilal/ecommerce-frontend:latest --name ecommerce-cluster

# Deploy with node affinity
./deploy-with-node-affinity.sh

# Show final status
echo ""
echo "Final Deployment Status:"
kubectl get pods -n ecommerce-dev -o wide
kubectl get svc -n ecommerce-dev
