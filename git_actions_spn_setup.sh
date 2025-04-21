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
SP_NAME="github-deploy-sp"
ACR_NAME="acrdevstorecluster"
AKS_NAME="dev-store-cluster"

SP_JSON=$(az ad sp create-for-rbac \
    --name "$SP_NAME" \
    --scope /subscriptions/$SUB_ID/resourceGroups/$RG_NAME \
    --role Contributor \
    --json-auth)

# === Output credentials ===
echo ""
echo "✅ DONE! Paste the following into your GitHub secret 'AZURE_CREDENTIALS':"
echo ""
echo "$SP_JSON" | jq
