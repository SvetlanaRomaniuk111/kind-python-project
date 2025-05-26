#!/bin/bash
set -e

echo "📦 Installing kind (if needed)..."
if ! command -v kind &> /dev/null; then
  curl -Lo kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
  chmod +x kind
  sudo mv kind /usr/local/bin/
fi

echo "📦 Installing kubectl (if needed)..."
if ! command -v kubectl &> /dev/null; then
  curl -LO "https://dl.k8s.io/release/v1.32.2/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi

echo "🚀 Creating Kind cluster..."
kind create cluster --name dev --wait 60s

echo "🐳 Building Docker image..."
docker build -t my-python-app:latest .

echo "📤 Loading image into Kind..."
kind load docker-image my-python-app:latest --name dev

echo "📄 Applying manifests..."
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

echo "🌐 Installing ingress-nginx..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.0/deploy/static/provider/kind/deploy.yaml

echo "🏷 Labeling node for ingress..."
NODE=$(kubectl get nodes -o jsonpath="{.items[0].metadata.name}")
kubectl label node "$NODE" ingress-ready=true --overwrite

echo "⏳ Waiting for ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

echo "🧩 Applying ingress.yaml..."
kubectl apply -f ingress.yaml

echo "✅ Setup complete. Now run: ./start-port-forward.sh"