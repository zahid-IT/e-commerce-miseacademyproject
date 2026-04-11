.PHONY: help install build push deploy-dev deploy-staging deploy-prod test clean

help:
	@echo "Available commands:"
	@echo "  make install-deps    - Install dependencies"
	@echo "  make build          - Build Docker images"
	@echo "  make push           - Push images to registry"
	@echo "  make deploy-dev     - Deploy to development"
	@echo "  make deploy-staging - Deploy to staging"
	@echo "  make deploy-prod    - Deploy to production"
	@echo "  make test           - Run tests"
	@echo "  make clean          - Clean up"

install-deps:
	cd backend && npm install
	cd frontend && npm install

build:
	@echo "Building backend image..."
	docker build -t $(REGISTRY)/backend:$(TAG) ./backend
	@echo "Building frontend image..."
	docker build -t $(REGISTRY)/frontend:$(TAG) ./frontend

push:
	docker push $(REGISTRY)/backend:$(TAG)
	docker push $(REGISTRY)/frontend:$(TAG)

deploy-dev:
	helm upgrade --install ecommerce-backend ./helm/backend \
		--namespace ecommerce-dev --create-namespace \
		-f ./helm/backend/values-dev.yaml
	helm upgrade --install ecommerce-frontend ./helm/frontend \
		--namespace ecommerce-dev \
		-f ./helm/frontend/values-dev.yaml

deploy-staging:
	helm upgrade --install ecommerce-backend ./helm/backend \
		--namespace ecommerce-staging --create-namespace \
		-f ./helm/backend/values-staging.yaml
	helm upgrade --install ecommerce-frontend ./helm/frontend \
		--namespace ecommerce-staging \
		-f ./helm/frontend/values-staging.yaml

deploy-prod:
	helm upgrade --install ecommerce-backend ./helm/backend \
		--namespace ecommerce-prod --create-namespace \
		-f ./helm/backend/values-production.yaml
	helm upgrade --install ecommerce-frontend ./helm/frontend \
		--namespace ecommerce-prod \
		-f ./helm/frontend/values-production.yaml

test:
	cd backend && npm test
	cd frontend && npm test
	helm test ecommerce-backend -n ecommerce-dev

clean:
	kubectl delete namespace ecommerce-dev ecommerce-staging ecommerce-prod --ignore-not-found
	rm -rf backend/node_modules frontend/node_modules

rollback-dev:
	helm rollback ecommerce-backend -n ecommerce-dev
	helm rollback ecommerce-frontend -n ecommerce-dev

status:
	kubectl get pods -n ecommerce-dev
	kubectl get pods -n ecommerce-staging
	kubectl get pods -n ecommerce-prod
