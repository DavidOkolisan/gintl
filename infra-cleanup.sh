#!/bin/bash
# ================================================
# Script Name: infra-cleanup.sh
# Description: Cleanup resource group containing resources (including blob used for terraform state remote storage)
# Author: David Okolisan
# Version: 1.0.0
# Last Updated: 2025-04-14
# ================================================
#
# Usage:
#   ./infra-cleanup.sh
#
# Dependencies:
#   - az login
# ================================================

RG_NAME="dev-rg"

# Login to Azure (if not already)
# az login

# Delete RG
az group delete --name $RG_NAME --yes

# Delete backend file (if exists) since it's been created with boostrap script
if [[ -f ./infra/backend.tf ]];
  then rm ./infra/backend.tf;
fi

echo "Resource group $RG_NAME deleted successfully"