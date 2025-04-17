#!/bin/bash
# ================================================
# Script Name: local-test.sh
# Description: Used for local Kubernetes test
# Author: David Okolisan
# Version: 1.0.0
# Last Updated: 2025-04-14
# ================================================
#
# Usage:
#   ./local-test.sh
#
# Dependencies:
#   - minikube tunnel # minikube tunnel should be running
# ================================================

# Switch to minikube docker daemon in order to make images accessible to Kubernetes
eval $(minikube -p minikube docker-env)

# Build images
SERVICES=("order-service" "product-service" "store-front")
for SERVICE in "${SERVICES[@]}"; do
  echo "Building $SERVICE..."
  docker build -t $SERVICE ../src/$SERVICE
done

# Build k8s resources
cp "../k8s/main.yaml" .
sed -i "" "s#^\( *image:\) *ghcr.io/azure-samples/aks-store-demo/order-service:latest\$#\1 order-service:latest\n        imagePullPolicy: Never#g" main.yaml
sed -i "" "s#^\( *image:\) *ghcr.io/azure-samples/aks-store-demo/product-service:latest\$#\1 product-service:latest\n        imagePullPolicy: Never#g" main.yaml
sed -i "" "s#^\( *image:\) *ghcr.io/azure-samples/aks-store-demo/store-front:latest\$#\1 store-front:latest\n        imagePullPolicy: Never#g" main.yaml
sed -i "" "s#^\( *host:\) *store-front.example.com\$#\1 localhost#g" main.yaml
kubectl apply -f main.yaml

# Check if products are loaded - sleep required until pods are up and running
#sleep 120
curl http://localhost:80/products
if [[ $? -eq 0 ]]; then
  printf "\n****************************\nTest executed successfully!\n****************************"
else
  printf "\n****************************\nTest failed! Exiting..\n****************************"
  exit 1
fi

# Delete k8s resources
kubectl delete -f main.yaml

# Cleanup minikube docker daemon images
docker rmi store-front product-service order-service -f

# Remove temp manifest file
rm ./main.yaml

# Role back to local daemon
eval $(minikube docker-env -u)