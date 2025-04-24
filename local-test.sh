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
GREEN='\033[1;32m'
BOLD='\033[1;37m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_help() {
  echo -e "${BOLD}Usage:${NC} $0 [command] [options]\n"

  echo -e "${BOLD}Available commands:${NC}"
  echo -e "  ${GREEN}start${NC}    - Start local test environment"
  echo -e "  ${GREEN}cleanup${NC} - Cleanup all test resources"
  echo -e "  ${GREEN}--help${NC}  - Show this help message\n"

  echo -e "${BOLD}Examples:${NC}"
  echo -e "  ${YELLOW}$0 start helm${NC}            # Start helm setup"
  echo -e "  ${YELLOW}$0 execute${NC}               # Execute local test"
  echo -e "  ${YELLOW}$0 cleanup${NC}               # Remove test environment"
}

start() {
  echo -e "${GREEN}Starting local test environment...${NC}"
  # Switch to minikube docker daemon in order to make images accessible to Kubernetes
  eval $(minikube -p minikube docker-env)

  # Build images
  build_images

  if [[ "$1" == "helm" ]]; then
    start_helm
  elif [[ "$1" == "kube"  ]]; then
    start_kubernetes
  else
    echo -e "${RED}Error occurred while starting test environment...${NC}" && cleanup
  fi
}

build_images() {
  SERVICES=("order-service" "product-service" "store-front")
  for SERVICE in "${SERVICES[@]}"; do
    echo "Building $SERVICE..."
    docker build -t $SERVICE ./src/$SERVICE
  done
}

start_helm() {
  local chart="store-app"
  helm install $chart ./helm/$chart --values ./helm/$chart/values-local.yaml
}

start_kubernetes() {
  # Build k8s resources
  cp "./k8s/main.yaml" .
  sed -i "" "s#^\( *image:\) *acrdevstorecluster.azurecr.io/order-service:latest\$#\1 order-service:latest\n        imagePullPolicy: Never#g" main.yaml
  sed -i "" "s#^\( *image:\) *acrdevstorecluster.azurecr.io/product-service:latest\$#\1 product-service:latest\n        imagePullPolicy: Never#g" main.yaml
  sed -i "" "s#^\( *image:\) *acrdevstorecluster.azurecr.io/store-front:latest\$#\1 store-front:latest\n        imagePullPolicy: Never#g" main.yaml
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
  cleanup_kubernetes

  # Cleanup minikube docker daemon images
  eval $(minikube -p minikube docker-env)
  docker rmi store-front product-service order-service -f

  # Role back to local daemon
  eval $(minikube docker-env -u)
}

cleanup_kubernetes() {
  if helm status store-app &>/dev/null; then
    helm uninstall store-app
  else
    kubectl delete -f main.yaml
    # Remove temp manifest file
    rm ./main.yaml
  fi
}

case "$1" in
  --start|-s|start)
    start $2
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