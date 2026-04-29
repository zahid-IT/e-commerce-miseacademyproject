#!/bin/bash

<<<<<<< HEAD





set -e





echo "========================================="


echo "🚀 Complete KIND Cluster Setup"


echo "========================================="





# Colors for output


RED='\033[0;31m'


GREEN='\033[0;32m'


YELLOW='\033[1;33m'


BLUE='\033[0;34m'


NC='\033[0m' # No Color





# ============================================


# 1. SYSTEM CHECKS & PREREQUISITES


# ============================================


echo -e "${BLUE}📋 Step 1: Checking system requirements...${NC}"





# Check Ubuntu version


if [[ ! -f /etc/os-release ]]; then


    echo -e "${RED}❌ This script is designed for Ubuntu systems${NC}"


    exit 1


fi





# Check available memory


TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')


if [ $TOTAL_MEM -lt 4000 ]; then


    echo -e "${YELLOW}⚠️  Warning: You have ${TOTAL_MEM}MB RAM. Recommended: 4GB+ for 3 workers${NC}"


    echo -e "${YELLOW}   Will proceed with reduced resource allocation${NC}"


fi





# ============================================


# 2. INSTALL DOCKER


# ============================================


echo -e "${BLUE}🐳 Step 2: Installing Docker...${NC}"





if ! command -v docker &> /dev/null; then


    echo "Installing Docker..."


    sudo apt-get update


    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common


    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg


    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


    sudo apt-get update


    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin


    echo -e "${GREEN}✅ Docker installed successfully${NC}"


else


    echo -e "${GREEN}✅ Docker already installed${NC}"


fi





# ============================================


# 3. CONFIGURE DOCKER PERMISSIONS


# ============================================


echo -e "${BLUE}🔧 Step 3: Configuring Docker permissions...${NC}"





# Add current user to docker group


if ! groups $USER | grep -q docker; then


    sudo usermod -aG docker $USER


    echo -e "${YELLOW}⚠️  Added user to docker group. You may need to log out and back in for changes to take effect${NC}"


    echo -e "${YELLOW}   For now, continuing with sudo where needed...${NC}"


fi





# Fix Docker socket permissions


sudo chmod 666 /var/run/docker.sock 2>/dev/null || true





# Enable Docker to start on boot


sudo systemctl enable docker


sudo systemctl start docker





# Test Docker


if docker ps &> /dev/null; then


    echo -e "${GREEN}✅ Docker is working correctly${NC}"


else


    echo -e "${RED}❌ Docker permission issues. Trying fix...${NC}"


    sudo chmod 666 /var/run/docker.sock


    newgrp docker


fi





# ============================================


# 4. INSTALL KUBECTL


# ============================================


echo -e "${BLUE}📦 Step 4: Installing kubectl...${NC}"





if ! command -v kubectl &> /dev/null; then


    echo "Downloading kubectl..."


    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"


    chmod +x kubectl


    sudo mv kubectl /usr/local/bin/kubectl


    


    # Verify installation


    kubectl version --client


    echo -e "${GREEN}✅ kubectl installed successfully${NC}"


else


    echo -e "${GREEN}✅ kubectl already installed${NC}"


fi





# ============================================


# 5. INSTALL KIND


# ============================================


echo -e "${BLUE}🎯 Step 5: Installing KIND...${NC}"





if ! command -v kind &> /dev/null; then


    echo "Downloading KIND..."


    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64


    chmod +x ./kind


    sudo mv ./kind /usr/local/bin/kind


    


    # Verify installation


    kind version


    echo -e "${GREEN}✅ KIND installed successfully${NC}"


else


    echo -e "${GREEN}✅ KIND already installed${NC}"


fi





# ============================================


# 6. INSTALL HELM


# ============================================


echo -e "${BLUE}⛵ Step 6: Installing Helm...${NC}"





if ! command -v helm &> /dev/null; then


    echo "Downloading Helm..."


    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3


    chmod 700 get_helm.sh


    ./get_helm.sh


    


    # Verify installation


    helm version


    echo -e "${GREEN}✅ Helm installed successfully${NC}"


else


    echo -e "${GREEN}✅ Helm already installed${NC}"


fi





# ============================================


# 7. CREATE KIND CLUSTER WITH 3 WORKER NODES


# ============================================


echo -e "${BLUE}🏗️  Step 7: Creating KIND cluster with 3 worker nodes...${NC}"





# Check if cluster exists and delete it


if kind get clusters 2>/dev/null | grep -q "ecommerce-cluster"; then


    echo "Deleting existing cluster..."


    kind delete cluster --name ecommerce-cluster


fi





# Create optimized configuration for 3 workers


cat > kind-3workers-config.yaml << 'EOF'


kind: Cluster


apiVersion: kind.x-k8s.io/v1alpha4


name: ecommerce-cluster


nodes:


  # Control plane node


  - role: control-plane


    extraPortMappings:


      - containerPort: 30080


        hostPort: 30080


        protocol: TCP


      - containerPort: 30081


        hostPort: 30081


        protocol: TCP


      - containerPort: 30082


        hostPort: 30082


        protocol: TCP


    kubeadmConfigPatches:


      - |


        kind: InitConfiguration


        nodeRegistration:


          kubeletExtraArgs:


            node-labels: "node-role.kubernetes.io/master=true,node-type=control-plane"


  


  # Worker node 1 - Backend dedicated


  - role: worker


    extraMounts:


      - hostPath: /var/run/docker.sock


        containerPath: /var/run/docker.sock


    labels:


      node-role.kubernetes.io/worker: "true"


      workload-type: "backend"


    kubeadmConfigPatches:


      - |


        kind: JoinConfiguration


        nodeRegistration:


          kubeletExtraArgs:


            node-labels: "node-role.kubernetes.io/worker=true,workload=backend"


  


  # Worker node 2 - Frontend dedicated


  - role: worker


    labels:


      node-role.kubernetes.io/worker: "true"


      workload-type: "frontend"


    kubeadmConfigPatches:


      - |


        kind: JoinConfiguration


        nodeRegistration:


          kubeletExtraArgs:


            node-labels: "node-role.kubernetes.io/worker=true,workload=frontend"


  


  # Worker node 3 - MongoDB dedicated


  - role: worker


    labels:


      node-role.kubernetes.io/worker: "true"


      workload-type: "database"


    kubeadmConfigPatches:


      - |


        kind: JoinConfiguration


        nodeRegistration:


          kubeletExtraArgs:


            node-labels: "node-role.kubernetes.io/worker=true,workload=database"





# Network configuration


networking:


  apiServerAddress: "0.0.0.0"


  apiServerPort: 6443


  podSubnet: "10.244.0.0/16"


  serviceSubnet: "10.96.0.0/12"





# Feature gates


featureGates:


  EphemeralContainers: true





# Runtime configuration


containerdConfigPatches:


  - |-


    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:5000"]


      endpoint = ["http://kind-registry:5000"]


EOF





echo "Creating KIND cluster with 3 worker nodes..."


kind create cluster --config kind-3workers-config.yaml





if [ $? -eq 0 ]; then


    echo -e "${GREEN}✅ KIND cluster created successfully with 3 workers!${NC}"


else


    echo -e "${RED}❌ Failed to create KIND cluster${NC}"


    exit 1


fi





# ============================================


# 8. VERIFY CLUSTER STATUS


# ============================================


echo -e "${BLUE}🔍 Step 8: Verifying cluster status...${NC}"





# Set context


kubectl config use-context kind-ecommerce-cluster





# Wait for nodes to be ready


echo "Waiting for nodes to be ready..."


sleep 10


kubectl wait --for=condition=ready node --all --timeout=120s





# Show node information


echo -e "${GREEN}Cluster Nodes:${NC}"


kubectl get nodes -o wide





# Label nodes for workload distribution


echo "Applying workload labels..."


kubectl label node ecommerce-cluster-worker workload=backend --overwrite


kubectl label node ecommerce-cluster-worker2 workload=frontend --overwrite  


kubectl label node ecommerce-cluster-worker3 workload=database --overwrite





# ============================================


# 9. INSTALL METALLB (For LoadBalancer services)


# ============================================


echo -e "${BLUE}🌐 Step 9: Installing MetalLB for LoadBalancer support...${NC}"





kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml





# Wait for MetalLB pods


kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s





# Configure MetalLB


cat > metallb-config.yaml << 'EOF'


apiVersion: metallb.io/v1beta1


kind: IPAddressPool


metadata:


  name: kind-pool


  namespace: metallb-system


spec:


  addresses:


  - 172.18.0.100-172.18.0.200


---


apiVersion: metallb.io/v1beta1


kind: L2Advertisement


metadata:


  name: kind-l2


  namespace: metallb-system


spec:


  ipAddressPools:


  - kind-pool


EOF





kubectl apply -f metallb-config.yaml


echo -e "${GREEN}✅ MetalLB configured${NC}"





# ============================================


# 10. INSTALL INGRESS CONTROLLER (NGINX)


# ============================================


echo -e "${BLUE}🚪 Step 10: Installing NGINX Ingress Controller...${NC}"





kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml





# Wait for ingress controller


kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s


echo -e "${GREEN}✅ Ingress controller installed${NC}"





# ============================================


# 11. INSTALL METRICS SERVER


# ============================================


echo -e "${BLUE}📊 Step 11: Installing Metrics Server...${NC}"





kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml





# Patch metrics server for KIND


kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'





kubectl wait --namespace kube-system --for=condition=ready pod --selector=k8s-app=metrics-server --timeout=60s


echo -e "${GREEN}✅ Metrics server installed${NC}"





# ============================================


# 12. ADD HELM REPOSITORIES


# ============================================


echo -e "${BLUE}📚 Step 12: Adding Helm repositories...${NC}"





# Add Bitnami repo for MongoDB


helm repo add bitnami https://charts.bitnami.com/bitnami





# Add Prometheus community repo


helm repo add prometheus-community https://prometheus-community.github.io/helm-charts





# Add Elastic repo for EFK stack


helm repo add elastic https://helm.elastic.co





# Update all repos


helm repo update





echo -e "${GREEN}✅ Helm repositories configured${NC}"





# ============================================


# 13. CREATE NAMESPACES


# ============================================


echo -e "${BLUE}📁 Step 13: Creating namespaces...${NC}"





kubectl create namespace ecommerce-dev --dry-run=client -o yaml | kubectl apply -f -


kubectl create namespace ecommerce-staging --dry-run=client -o yaml | kubectl apply -f -


kubectl create namespace ecommerce-prod --dry-run=client -o yaml | kubectl apply -f -


kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -


kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -





echo -e "${GREEN}✅ Namespaces created${NC}"





# ============================================


# 14. SETUP LOCAL DOCKER REGISTRY (Optional)


# ============================================


echo -e "${BLUE}📦 Step 14: Setting up local Docker registry...${NC}"





if [ ! "$(docker ps -q -f name=kind-registry)" ]; then


    docker run -d --restart=always -p "5000:5000" --name "kind-registry" registry:2


fi





# Connect registry to KIND network


docker network connect kind "kind-registry" 2>/dev/null || true





echo -e "${GREEN}✅ Local registry configured at localhost:5000${NC}"





# ============================================


# 15. DISPLAY CLUSTER INFORMATION


# ============================================


echo ""


echo "========================================="


echo -e "${GREEN}✅ KIND Cluster Setup Complete!${NC}"


echo "========================================="


echo ""


echo -e "${BLUE}📊 Cluster Information:${NC}"


echo "  Cluster Name: ecommerce-cluster"


echo "  Nodes: 1 Control Plane + 3 Workers"


echo "  Namespaces: dev, staging, prod, monitoring, logging"


echo ""


echo -e "${BLUE}🎯 Node Assignments:${NC}"


echo "  Worker 1: Backend workloads (labeled: workload=backend)"


echo "  Worker 2: Frontend workloads (labeled: workload=frontend)"


echo "  Worker 3: Database workloads (labeled: workload=database)"


echo ""


echo -e "${BLUE}🔧 Tools Installed:${NC}"


echo "  ✓ Docker (with permissions configured)"


echo "  ✓ kubectl"


echo "  ✓ KIND"


echo "  ✓ Helm"


echo ""


echo -e "${BLUE}🌐 Components Deployed:${NC}"


echo "  ✓ MetalLB (LoadBalancer)"


echo "  ✓ NGINX Ingress Controller"


echo "  ✓ Metrics Server"


echo "  ✓ Local Docker Registry (port 5000)"


echo ""


echo -e "${BLUE}📝 Useful Commands:${NC}"


echo "  kubectl get nodes -o wide"


echo "  kubectl get pods -A"


echo "  kubectl top nodes"


echo "  helm list -A"


echo "  kind get clusters"


echo ""


echo -e "${BLUE}🚀 Next Steps - Deploy Your Application:${NC}"


echo "  1. Build images: docker build -t ecommerce-backend:latest ./backend"


echo "  2. Load to KIND: kind load docker-image ecommerce-backend:latest --name ecommerce-cluster"


echo "  3. Deploy: helm upgrade --install ecommerce-backend ./helm/backend -n ecommerce-dev"


echo ""


echo -e "${YELLOW}⚠️  Note: You may need to log out and back in for Docker group changes to take effect${NC}"


echo ""


=======
set -e

echo "========================================="
echo "🚀 Complete KIND Cluster Setup"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================
# 1. SYSTEM CHECKS & PREREQUISITES
# ============================================
echo -e "${BLUE}📋 Step 1: Checking system requirements...${NC}"

# Check Ubuntu version
if [[ ! -f /etc/os-release ]]; then
    echo -e "${RED}❌ This script is designed for Ubuntu systems${NC}"
    exit 1
fi

# Check available memory
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
if [ $TOTAL_MEM -lt 4000 ]; then
    echo -e "${YELLOW}⚠️  Warning: You have ${TOTAL_MEM}MB RAM. Recommended: 4GB+ for 3 workers${NC}"
    echo -e "${YELLOW}   Will proceed with reduced resource allocation${NC}"
fi

# ============================================
# 2. INSTALL DOCKER
# ============================================
echo -e "${BLUE}🐳 Step 2: Installing Docker...${NC}"

if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    echo -e "${GREEN}✅ Docker installed successfully${NC}"
else
    echo -e "${GREEN}✅ Docker already installed${NC}"
fi

# ============================================
# 3. CONFIGURE DOCKER PERMISSIONS
# ============================================
echo -e "${BLUE}🔧 Step 3: Configuring Docker permissions...${NC}"

# Add current user to docker group
if ! groups $USER | grep -q docker; then
    sudo usermod -aG docker $USER
    echo -e "${YELLOW}⚠️  Added user to docker group. You may need to log out and back in for changes to take effect${NC}"
    echo -e "${YELLOW}   For now, continuing with sudo where needed...${NC}"
fi

# Fix Docker socket permissions
sudo chmod 666 /var/run/docker.sock 2>/dev/null || true

# Enable Docker to start on boot
sudo systemctl enable docker
sudo systemctl start docker

# Test Docker
if docker ps &> /dev/null; then
    echo -e "${GREEN}✅ Docker is working correctly${NC}"
else
    echo -e "${RED}❌ Docker permission issues. Trying fix...${NC}"
    sudo chmod 666 /var/run/docker.sock
    newgrp docker
fi

# ============================================
# 4. INSTALL KUBECTL
# ============================================
echo -e "${BLUE}📦 Step 4: Installing kubectl...${NC}"

if ! command -v kubectl &> /dev/null; then
    echo "Downloading kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/kubectl
    
    # Verify installation
    kubectl version --client
    echo -e "${GREEN}✅ kubectl installed successfully${NC}"
else
    echo -e "${GREEN}✅ kubectl already installed${NC}"
fi

# ============================================
# 5. INSTALL KIND
# ============================================
echo -e "${BLUE}🎯 Step 5: Installing KIND...${NC}"

if ! command -v kind &> /dev/null; then
    echo "Downloading KIND..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    
    # Verify installation
    kind version
    echo -e "${GREEN}✅ KIND installed successfully${NC}"
else
    echo -e "${GREEN}✅ KIND already installed${NC}"
fi

# ============================================
# 6. INSTALL HELM
# ============================================
echo -e "${BLUE}⛵ Step 6: Installing Helm...${NC}"

if ! command -v helm &> /dev/null; then
    echo "Downloading Helm..."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    
    # Verify installation
    helm version
    echo -e "${GREEN}✅ Helm installed successfully${NC}"
else
    echo -e "${GREEN}✅ Helm already installed${NC}"
fi

# ============================================
# 7. CREATE KIND CLUSTER WITH 3 WORKER NODES
# ============================================
echo -e "${BLUE}🏗️  Step 7: Creating KIND cluster with 3 worker nodes...${NC}"

# Check if cluster exists and delete it
if kind get clusters 2>/dev/null | grep -q "ecommerce-cluster"; then
    echo "Deleting existing cluster..."
    kind delete cluster --name ecommerce-cluster
fi

# Create optimized configuration for 3 workers
cat > kind-3workers-config.yaml << 'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ecommerce-cluster
nodes:
  # Control plane node
  - role: control-plane
    extraPortMappings:
      - containerPort: 30080
        hostPort: 30080
        protocol: TCP
      - containerPort: 30081
        hostPort: 30081
        protocol: TCP
      - containerPort: 30082
        hostPort: 30082
        protocol: TCP
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "node-role.kubernetes.io/master=true,node-type=control-plane"
  
  # Worker node 1 - Backend dedicated
  - role: worker
    extraMounts:
      - hostPath: /var/run/docker.sock
        containerPath: /var/run/docker.sock
    labels:
      node-role.kubernetes.io/worker: "true"
      workload-type: "backend"
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "node-role.kubernetes.io/worker=true,workload=backend"
  
  # Worker node 2 - Frontend dedicated
  - role: worker
    labels:
      node-role.kubernetes.io/worker: "true"
      workload-type: "frontend"
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "node-role.kubernetes.io/worker=true,workload=frontend"
# Network configuration
networking:
  apiServerAddress: "0.0.0.0"
  apiServerPort: 6443
  podSubnet: "10.244.0.0/16"
  serviceSubnet: "10.96.0.0/12"

# Feature gates
featureGates:
  EphemeralContainers: true

# Runtime configuration
containerdConfigPatches:
  - |-
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:5000"]
      endpoint = ["http://kind-registry:5000"]
EOF

echo "Creating KIND cluster with 3 worker nodes..."
kind create cluster --config kind-3workers-config.yaml

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ KIND cluster created successfully with 3 workers!${NC}"
else
    echo -e "${RED}❌ Failed to create KIND cluster${NC}"
    exit 1
fi

# ============================================
# 8. VERIFY CLUSTER STATUS
# ============================================
echo -e "${BLUE}🔍 Step 8: Verifying cluster status...${NC}"

# Set context
kubectl config use-context kind-ecommerce-cluster

# Wait for nodes to be ready
echo "Waiting for nodes to be ready..."
sleep 10
kubectl wait --for=condition=ready node --all --timeout=120s

# Show node information
echo -e "${GREEN}Cluster Nodes:${NC}"
kubectl get nodes -o wide

# Label nodes for workload distribution
echo "Applying workload labels..."
kubectl label node ecommerce-cluster-worker workload=backend --overwrite
kubectl label node ecommerce-cluster-worker2 workload=frontend --overwrite  
kubectl label node ecommerce-cluster-worker3 workload=database --overwrite

# ============================================
# 9. INSTALL METALLB (For LoadBalancer services)
# ============================================
echo -e "${BLUE}🌐 Step 9: Installing MetalLB for LoadBalancer support...${NC}"

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml

# Wait for MetalLB pods
kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s

# Configure MetalLB
cat > metallb-config.yaml << 'EOF'
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: kind-pool
  namespace: metallb-system
spec:
  addresses:
  - 172.18.0.100-172.18.0.200
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: kind-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - kind-pool
EOF

kubectl apply -f metallb-config.yaml
echo -e "${GREEN}✅ MetalLB configured${NC}"

# ============================================
# 10. INSTALL INGRESS CONTROLLER (NGINX)
# ============================================
echo -e "${BLUE}🚪 Step 10: Installing NGINX Ingress Controller...${NC}"

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s
echo -e "${GREEN}✅ Ingress controller installed${NC}"

# ============================================
# 11. INSTALL METRICS SERVER
# ============================================
echo -e "${BLUE}📊 Step 11: Installing Metrics Server...${NC}"

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch metrics server for KIND
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

kubectl wait --namespace kube-system --for=condition=ready pod --selector=k8s-app=metrics-server --timeout=60s
echo -e "${GREEN}✅ Metrics server installed${NC}"

# ============================================
# 12. ADD HELM REPOSITORIES
# ============================================
echo -e "${BLUE}📚 Step 12: Adding Helm repositories...${NC}"

# Add Bitnami repo for MongoDB
helm repo add bitnami https://charts.bitnami.com/bitnami

# Add Prometheus community repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Add Elastic repo for EFK stack
helm repo add elastic https://helm.elastic.co

# Update all repos
helm repo update

echo -e "${GREEN}✅ Helm repositories configured${NC}"

# ============================================
# 13. CREATE NAMESPACES
# ============================================
echo -e "${BLUE}📁 Step 13: Creating namespaces...${NC}"

kubectl create namespace ecommerce-dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ecommerce-staging --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ecommerce-prod --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✅ Namespaces created${NC}"

# ============================================
# 14. SETUP LOCAL DOCKER REGISTRY (Optional)
# ============================================
echo -e "${BLUE}📦 Step 14: Setting up local Docker registry...${NC}"

if [ ! "$(docker ps -q -f name=kind-registry)" ]; then
    docker run -d --restart=always -p "5000:5000" --name "kind-registry" registry:2
fi

# Connect registry to KIND network
docker network connect kind "kind-registry" 2>/dev/null || true

echo -e "${GREEN}✅ Local registry configured at localhost:5000${NC}"

# ============================================
# 15. DISPLAY CLUSTER INFORMATION
# ============================================
echo ""
echo "========================================="
echo -e "${GREEN}✅ KIND Cluster Setup Complete!${NC}"
echo "========================================="
echo ""
echo -e "${BLUE}📊 Cluster Information:${NC}"
echo "  Cluster Name: ecommerce-cluster"
echo "  Nodes: 1 Control Plane + 3 Workers"
echo "  Namespaces: dev, staging, prod, monitoring, logging"
echo ""
echo -e "${BLUE}🎯 Node Assignments:${NC}"
echo "  Worker 1: Backend workloads (labeled: workload=backend)"
echo "  Worker 2: Frontend workloads (labeled: workload=frontend)"
echo "  Worker 3: Database workloads (labeled: workload=database)"
echo ""
echo -e "${BLUE}🔧 Tools Installed:${NC}"
echo "  ✓ Docker (with permissions configured)"
echo "  ✓ kubectl"
echo "  ✓ KIND"
echo "  ✓ Helm"
echo ""
echo -e "${BLUE}🌐 Components Deployed:${NC}"
echo "  ✓ MetalLB (LoadBalancer)"
echo "  ✓ NGINX Ingress Controller"
echo "  ✓ Metrics Server"
echo "  ✓ Local Docker Registry (port 5000)"
echo ""
echo -e "${BLUE}📝 Useful Commands:${NC}"
echo "  kubectl get nodes -o wide"
echo "  kubectl get pods -A"
echo "  kubectl top nodes"
echo "  helm list -A"
echo "  kind get clusters"
echo ""
echo -e "${BLUE}🚀 Next Steps - Deploy Your Application:${NC}"
echo "  1. Build images: docker build -t ecommerce-backend:latest ./backend"
echo "  2. Load to KIND: kind load docker-image ecommerce-backend:latest --name ecommerce-cluster"
echo "  3. Deploy: helm upgrade --install ecommerce-backend ./helm/backend -n ecommerce-dev"
echo ""
echo -e "${YELLOW}⚠️  Note: You may need to log out and back in for Docker group changes to take effect${NC}"
echo ""
>>>>>>> main
echo "========================================="
