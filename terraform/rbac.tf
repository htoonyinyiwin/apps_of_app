# --- Azure AD Groups (requires Groups Administrator role) ---
# Commented out — current user doesn't have AD admin rights in this tenant.
# In enterprise, an AD admin would create these groups and assign users to them.
#
# resource "azuread_group" "aks_admins" {
#   display_name     = "aks-admins"
#   security_enabled = true
# }
#
# resource "azuread_group" "aks_developers" {
#   display_name     = "aks-developers"
#   security_enabled = true
# }
#
# resource "azurerm_role_assignment" "aks_admins" {
#   scope                = azurerm_kubernetes_cluster.aks.id
#   role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
#   principal_id         = azuread_group.aks_admins.object_id
# }
#
# resource "azurerm_role_assignment" "aks_developers" {
#   scope                = azurerm_kubernetes_cluster.aks.id
#   role_definition_name = "Azure Kubernetes Service Cluster User Role"
#   principal_id         = azuread_group.aks_developers.object_id
# }

# --- Direct User Role Assignment (Option 2: no AD admin needed) ---

data "azurerm_client_config" "current" {}

# Lets user get credentials: az aks get-credentials
resource "azurerm_role_assignment" "current_user_admin" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Lets user run kubectl commands when Azure RBAC is enabled
resource "azurerm_role_assignment" "current_user_rbac_admin" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}
