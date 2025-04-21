#!/bin/bash

# ================================================
# Script Name: infra-boostrap.sh
# Description: Bootstrap resource group as well as AZ blob used for remote storing terraform state
# Author: David Okolisan
# Version: 1.0.0
# Last Updated: 2025-04-14
# ================================================
#
# Usage:
#   ./infra-boostrap.sh
#
# Dependencies:
#   - az login
# ================================================

# Variables are hardcoded here, of course various kind of setup can be done around them
RG_NAME="dev-rg"
STORAGE_ACCOUNT_NAME="devstoredemo5a815f"
CONTAINER_NAME="dev-store-demo-container-tfstate"
LOCATION="westeurope"


cat > ./infra/backend.tf <<EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "$RG_NAME"
    storage_account_name = "$STORAGE_ACCOUNT_NAME"
    container_name       = "$CONTAINER_NAME"
    key                  = "dev.tfstate"
    use_oidc             = true
  }
}
EOF

# Login to Azure (if not already)
# az login

# Create RG
az group create --name $RG_NAME --location $LOCATION

# Create Storage Account
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --sku Standard_LRS

# Create Container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --auth-mode login

echo "Backend storage ready! Update backend.tf with:"
echo "storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
echo "storage_container_name = \"$CONTAINER_NAME\""