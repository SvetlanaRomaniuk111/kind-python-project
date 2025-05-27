#!/bin/bash

CLUSTER_NAME="kind-dev"
PORT_LOCAL=8080
PORT_REMOTE=80
NAMESPACE="ingress-nginx"
SERVICE="ingress-nginx-controller"

echo "🔍 Checking if kind cluster '$CLUSTER_NAME' exists..."
if ! kind get clusters | grep -q "$CLUSTER_NAME"; then
    echo "🚀 Creating kind cluster '$CLUSTER_NAME'..."
    kind create cluster --name "$CLUSTER_NAME" --wait 60s
else
    echo "✅ Cluster '$CLUSTER_NAME' already exists."
fi

echo "🔄 Setting kubectl context to 'kind-$CLUSTER_NAME'..."
kubectl config use-context "kind-$CLUSTER_NAME"

echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=60s

echo "🌐 Setting up port forwarding: localhost:$PORT_LOCAL → $SERVICE:$PORT_REMOTE"
kubectl port-forward -n "$NAMESPACE" service/"$SERVICE" "$PORT_LOCAL":"$PORT_REMOTE" > /dev/null 2>&1 &
PF_PID=$!
sleep 2

echo "🌍 Opening http://localhost:$PORT_LOCAL in browser..."
xdg-open "http://localhost:$PORT_LOCAL" >/dev/null 2>&1 &

echo "🟢 Ready! Port-forward PID: $PF_PID"
