terraform {
  backend "azurerm" {
    resource_group_name  = "dev-rg"
    storage_account_name = "devstoredemo5a815f"
    container_name       = "dev-store-demo-container-tfstate"
    key                  = "dev.tfstate"
    use_oidc             = true
  }
}
