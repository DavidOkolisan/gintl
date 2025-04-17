output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "ingress_ip_instructions" {
  value = <<EOT
Ingress IP will be available after a few minutes. Run:
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
EOT
}

# output "bastion_hostname" {
#   value = var.bastion_enabled ? azurerm_bastion_host.main[0].name : null
# }