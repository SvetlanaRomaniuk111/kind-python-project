#!/bin/bash
set -e

echo "📦 Checking required tools..."

# Install kind if not present
if ! command -v kind &> /dev/null; then
  echo "🔧 Installing kind..."
  curl -Lo kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
  chmod +x kind
  sudo mv kind /usr/local/bin/
fi

# Install kubectl if not present
if ! command -v kubectl &> /dev/null; then
  echo "🔧 Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/v1.32.2/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi

# Check Docker is running
echo "🐳 Checking Docker..."
docker info > /dev/null || { echo "❌ Docker is not running!"; exit 1; }

# Create cluster if not already present
if ! kind get clusters | grep -q dev; then
  echo "🚀 Creating Kind cluster..."
  kind create cluster --name dev --wait 60s
else
  echo "✅ Kind cluster 'dev' already exists"
fi

# Ensure context is set
kubectl config use-context kind-dev

echo "🐍 Building Docker image..."
docker build -t my-python-app:latest .

echo "📤 Loading image into Kind..."
kind load docker-image my-python-app:latest --name dev

echo "📄 Applying Kubernetes manifests..."
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

echo "🌐 Installing Ingress NGINX..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.0/deploy/static/provider/kind/deploy.yaml

echo "🏷 Labeling node for ingress..."
NODE=$(kubectl get nodes -o jsonpath="{.items[0].metadata.name}")
kubectl label node "$NODE" ingress-ready=true --overwrite

echo "⏳ Waiting for Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

echo "🧩 Applying ingress.yaml..."
kubectl apply -f ingress.yaml

echo "✅ Setup complete!"
echo "👉 Run this to start port-forwarding:"
echo "./start-port-forward.sh"