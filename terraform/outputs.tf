output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "kube_config_command" {
  description = "Run this to configure kubectl"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}

output "external_secrets_client_id" {
  description = "Client ID for External Secrets Operator workload identity"
  value       = azurerm_user_assigned_identity.external_secrets.client_id
}

output "keyvault_name" {
  value = azurerm_key_vault.main.name
}
