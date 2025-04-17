provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.21.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Create resource group - we will create it at boostrap state in order to setup remote tfstate handling
# resource "azurerm_resource_group" "store_demo" {
#   name     = var.resource_group_name
#   location = var.location
# }
