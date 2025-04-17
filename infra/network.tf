# resource "azurerm_virtual_network" "main" {
#   name                = "${var.aks_cluster_name}-vnet"
#   address_space       = ["10.0.0.0/16"]
#   location            = var.location
#   resource_group_name = var.resource_group_name
# }
#
# resource "azurerm_subnet" "aks" {
#   name                 = "${var.resource_group_name}-aks-subnet"
#   resource_group_name  = var.resource_group_name
#   virtual_network_name = azurerm_virtual_network.main.name
#   address_prefixes     = ["10.0.1.0/24"]
# }
#
# resource "azurerm_subnet" "bastion" {
#   count                = var.bastion_enabled ? 1 : 0
#   name                 = "AzureBastionSubnet"  # Must use this exact name
#   resource_group_name  = var.resource_group_name
#   virtual_network_name = azurerm_virtual_network.main.name
#   address_prefixes     = ["10.0.2.0/24"]
# }
#
# resource "azurerm_bastion_host" "main" {
#   count               = var.bastion_enabled ? 1 : 0
#   name                = "${var.aks_cluster_name}-bastion"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#
#   ip_configuration {
#     name                 = "configuration"
#     subnet_id            = azurerm_subnet.bastion[0].id
#     public_ip_address_id = azurerm_public_ip.bastion[0].id
#   }
# }
#
# resource "azurerm_public_ip" "bastion" {
#   count               = var.bastion_enabled ? 1 : 0
#   name                = "${var.aks_cluster_name}-bastion-ip"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }