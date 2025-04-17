#!/bin/bash
# ================================================
# Script Name: spn_cleanup.sh
# Description: Cleanup service principal used for CI/CD pipeline
# Author: David Okolisan
# Version: 1.0.0
# Last Updated: 2025-04-14
# ================================================
#
# Usage:
#   ./spn_cleanup.sh
#
# Dependencies:
#   - az login
# ================================================

# Login to Azure (if not already)
# az login

RG_NAME="dev-rg"
SUB_ID=$(az account show --query id --output tsv)

# Get appId
appId=$(az ad sp list --query "[?contains(displayName, 'aks-store-demo-spn')].appId" -o tsv)

# Delete spn
az ad sp delete --id $appId

# Assign AKS permissions
az role assignment delete --assignee $appId