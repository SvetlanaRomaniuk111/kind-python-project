#!/bin/bash
echo "Starting port-forward for ingress-nginx-controller (8080:80)..."
kubectl port-forward --namespace ingress-nginx service/ingress-nginx-controller 8080:80