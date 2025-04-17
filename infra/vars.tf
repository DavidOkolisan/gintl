variable "location" {
  description = "Region in which resource will be deployed"
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Resource group for deployed resources(environment)"
  type        = string
  default     = "dev-rg"
}

# Export your subscription id as TF_VAR_subscription_id=.. 
# or enter along with plan/apply cmd
variable "subscription_id" {
  description = "Subscription id"
  type      = string
  sensitive = true
}


variable "aks_cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "dev-store-cluster"
}
# variable "bastion_enabled" {
#   description = "Deploy Azure Bastion Host?"
#   type        = bool
#   default     = true
# }
