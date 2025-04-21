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
#   ./local-test.sh start
#   ./local-test.sh cleanup
#   ./local-test.sh --help
#
# Dependencies:
#   - minikube tunnel # minikube tunnel should be running
# ================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

show_help() {
  cat <<EOF
Usage: $0 [command]

Available commands:
  start     - Start test
  cleanup   - Cleanup resources
  --help    - Show this help message

Examples:
  $0 start     # Initialize test setup
  $0 cleanup   # Tear down test environment
EOF
}

start() {
  echo -e "${GREEN}Starting local test environment...${NC}"
  # Switch to minikube docker daemon in order to make images accessible to Kubernetes
  eval $(minikube -p minikube docker-env)

  # Build images
  SERVICES=("order-service" "product-service" "store-front")
  for SERVICE in "${SERVICES[@]}"; do
    echo "Building $SERVICE..."
    docker build -t $SERVICE ./src/$SERVICE
  done

  # Build k8s resources
  cp "./k8s/main.yaml" .
  sed -i "" "s#^\( *image:\) *ghcr.io/azure-samples/aks-store-demo/order-service:latest\$#\1 order-service:latest\n        imagePullPolicy: Never#g" main.yaml
  sed -i "" "s#^\( *image:\) *ghcr.io/azure-samples/aks-store-demo/product-service:latest\$#\1 product-service:latest\n        imagePullPolicy: Never#g" main.yaml
  sed -i "" "s#^\( *image:\) *ghcr.io/azure-samples/aks-store-demo/store-front:latest\$#\1 store-front:latest\n        imagePullPolicy: Never#g" main.yaml
  sed -i "" "s#^\( *-\ host:\) *store-front.example.com\$#\1 localhost#g" main.yaml
  kubectl apply -f main.yaml

  attempt=1
  MAX_RETRIES=12
  while (( attempt <= $MAX_RETRIES )); do
    if check_pods_ready; then
      echo -e "${GREEN}All pods are ready!You can proceed with executing test!${NC}"
      exit 0
    fi

    echo "Attempt $attempt/$MAX_RETRIES - Retrying in 10 seconds..."
    sleep 10
    ((attempt++))
  done
  echo -e "${RED}Error occurred while starting test environment...${NC}" && cleanup
}

check_pods_ready() {
  kubectl wait --for=condition=Ready \
    --timeout=0s \
    --all pods >/dev/null 2>&1
}

execute() {
  # Check if products are loaded - sleep required until pods are up and running
#  sudo minikube tunnel &
#  m_pid=$!
  curl http://localhost:80/products >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo -e "\n${GREEN}****************************\nTest executed successfully!\n****************************${NC}"
#    kill $m_pid
  else
    echo -e "\n${RED}****************************\nTest failed! Exiting..\n****************************${NC}"
#    kill $m_pid
#    cleanup
    exit 1
  fi
}

#open_minikube_tunnel() {
#  sudo -b minikube tunnel
#}

#close_minikube_tunnel() {
#
#}

cleanup() {
  echo -e "\n${RED}****************************\nCleaning up...\n****************************${NC}"

  # Delete k8s resources
  kubectl delete -f main.yaml

  # Cleanup minikube docker daemon images
  eval $(minikube -p minikube docker-env)
  docker rmi store-front product-service order-service -f

  # Remove temp manifest file
  rm ./main.yaml

  # Role back to local daemon
  eval $(minikube docker-env -u)
}

case "$1" in
  --start|-s|start)
    start
    ;;
  --cleanup|-c|cleanup)
    cleanup
    ;;
  --execute|-e|execute)
    execute
    ;;
  --help|-h|help)
    show_help
    ;;
  *)
    echo -e "${RED}Error: Unknown command '$1'${NC}"
    show_help
    exit 1
    ;;
esac