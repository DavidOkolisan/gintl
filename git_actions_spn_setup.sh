#!/bin/bash
# ================================================
# Script Name: git_actions_spn_setup.sh
# Description: Setup service principal used for CI/CD pipeline for git actions
# Author: David Okolisan
# Version: 1.0.0
# Last Updated: 2025-04-14
# ================================================
#
# Usage:
#   ./git_actions_spn_setup.sh
#
# Dependencies:
#   - az login
# ================================================

# 1. Login to Azure (if not already)
# az login

RG_NAME="dev-rg"
SUB_ID=$(az account show --query id --output tsv)

# 2. Create SPN with limited ACR + AKS access
SP_JSON=$(az ad sp create-for-rbac \
  --name cicd-acr-push \
  --role AcrPush \
  --scopes /subscriptions/$SUB_ID/resourceGroups/$RG_NAME \
  --output json)

# Extract fields
CLIENT_ID=$(echo "$SP_JSON" | jq -r .appId)
CLIENT_SECRET=$(echo "$SP_JSON" | jq -r .password)
TENANT_ID=$(echo "$SP_JSON" | jq -r .tenant)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Output full SDK Auth JSON
cat <<EOF
{
  "clientId": "$CLIENT_ID",
  "clientSecret": "$CLIENT_SECRET",
  "subscriptionId": "$SUBSCRIPTION_ID",
  "tenantId": "$TENANT_ID",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
EOF