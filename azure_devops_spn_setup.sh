#!/bin/bash
# ================================================
# Script Name: azure_devops_spn_setup.sh
# Description: Setup service principal used for CI/CD pipeline for azure devops
# Author: David Okolisan
# Version: 1.0.0
# Last Updated: 2025-04-14
# ================================================
#
# Usage:
#   ./azure_devops_spn_setup.sh
#
# Dependencies:
#   - az login
# ================================================

# 1. Login to Azure (if not already)
# az login

RG_NAME="dev-rg"
SUB_ID=$(az account show --query id --output tsv)

# 2. Create SPN with limited ACR + AKS access
data=$(az ad sp create-for-rbac \
  --name "cicd-acr-push" \
  --role "AcrPush" \
  --scopes /subscriptions/$SUB_ID/resourceGroups/$RG_NAME)

echo $data
APP_ID=$(echo $data | jq -r '.appId')

# 3. Assign AKS permissions
az role assignment create \
  --assignee "$APP_ID" \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope /subscriptions/$SUB_ID/resourceGroups/$RG_NAME