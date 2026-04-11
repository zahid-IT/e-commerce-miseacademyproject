#!/bin/bash
echo "Checking missing files..."

# Backend checks
[ -f backend/healthcheck.js ] || echo "❌ Missing backend/healthcheck.js"
[ -f backend/logger.js ] || echo "❌ Missing backend/logger.js"
[ -f backend/metrics.js ] || echo "❌ Missing backend/metrics.js"
[ -f backend/.env.example ] || echo "❌ Missing backend/.env.example"
[ -d backend/migrations ] || echo "❌ Missing backend/migrations/"

# Helm backend checks
[ -f helm/backend/templates/pvc.yaml ] || echo "❌ Missing helm/backend/templates/pvc.yaml"
[ -f helm/backend/templates/serviceaccount.yaml ] || echo "❌ Missing helm/backend/templates/serviceaccount.yaml"
[ -f helm/backend/templates/networkpolicy.yaml ] || echo "❌ Missing helm/backend/templates/networkpolicy.yaml"
[ -f helm/backend/templates/NOTES.txt ] || echo "❌ Missing helm/backend/templates/NOTES.txt"

# Helm frontend checks
[ -f helm/frontend/templates/service.yaml ] || echo "❌ Missing helm/frontend/templates/service.yaml"
[ -f helm/frontend/templates/ingress.yaml ] || echo "❌ Missing helm/frontend/templates/ingress.yaml"
[ -f helm/frontend/templates/configmap.yaml ] || echo "❌ Missing helm/frontend/templates/configmap.yaml"

# Root files
[ -f .gitignore ] || echo "❌ Missing .gitignore"
[ -f Makefile ] || echo "❌ Missing Makefile"
[ -f docker-compose.yml ] || echo "❌ Missing docker-compose.yml"

# Scripts
[ -f scripts/deploy.sh ] || echo "❌ Missing scripts/deploy.sh"
[ -f scripts/rollback.sh ] || echo "❌ Missing scripts/rollback.sh"

echo "Check complete!"
