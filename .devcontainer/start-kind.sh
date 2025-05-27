#!/bin/bash

set -e

CLUSTER_NAME="kind-dev"
CONTEXT_NAME="kind-$CLUSTER_NAME"
PORT_LOCAL=8080
PORT_REMOTE=80
NAMESPACE="ingress-nginx"
SERVICE="ingress-nginx-controller"

echo "🔍 Checking if 'kubectl' is available..."
if ! command -v kubectl &> /dev/null; then
    echo "📦 Installing kubectl..."
    curl -Lo kubectl https://dl.k8s.io/release/v1.30.1/bin/linux/amd64/kubectl
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

echo "🔍 Checking if kind cluster '$CLUSTER_NAME' exists..."
if ! kind get clusters | grep -q "$CLUSTER_NAME"; then
    echo "🚀 Creating kind cluster '$CLUSTER_NAME'..."
    kind create cluster --name "$CLUSTER_NAME" --wait 60s
else
    echo "✅ Cluster '$CLUSTER_NAME' already exists."
fi

echo "🔄 Setting kubectl context to '$CONTEXT_NAME'..."
kubectl config use-context "$CONTEXT_NAME"

echo "⏳ Waiting for cluster nodes to be Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=60s

echo "🌐 Checking for ingress-nginx..."
if ! kubectl get ns "$NAMESPACE" &> /dev/null; then
    echo "📥 Installing ingress-nginx..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/kind/deploy.yaml
    echo "⏳ Waiting for ingress-nginx pods..."
    kubectl wait --namespace "$NAMESPACE" --for=condition=Ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
else
    echo "✅ ingress-nginx already installed."
fi

echo "🌍 Creating test deployment..."
kubectl create deployment hello-k8s --image=nginxdemos/hello:plain-text --dry-run=client -o yaml | kubectl apply -f -
kubectl expose deployment hello-k8s --port=80 --target-port=80 --type=ClusterIP --dry-run=client -o yaml | kubectl apply -f -

echo "🛠 Creating Ingress rule..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: hello-k8s
              port:
                number: 80
EOF

echo "🔁 Waiting 5 seconds before forwarding..."
sleep 5

echo "🚪 Port forwarding $PORT_LOCAL → $SERVICE:$PORT_REMOTE"
kubectl port-forward -n "$NAMESPACE" service/"$SERVICE" "$PORT_LOCAL":"$PORT_REMOTE" > /dev/null 2>&1 &
PF_PID=$!

# Detect if running in Codespaces (GitHub environment)
if [ -n "$CODESPACES" ]; then
    URL="https://${CODESPACE_NAME}-${PORT_LOCAL}.app.github.dev"
    echo "🌐 Open in browser: $URL"
else
    echo "🌐 Opening http://localhost:$PORT_LOCAL in default browser..."
    xdg-open "http://localhost:$PORT_LOCAL" >/dev/null 2>&1 || echo "🔗 http://localhost:$PORT_LOCAL"
fi

echo "✅ Done! Port-forward PID: $PF_PID"