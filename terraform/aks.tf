resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.cluster_name

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.vm_size

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  azure_policy_enabled = true

  microsoft_defender {
    log_analytics_workspace_id = "/subscriptions/6d5a4a5c-4ba5-450e-ab55-a6e4dabfa9a4/resourceGroups/DefaultResourceGroup-SEA/providers/Microsoft.OperationalInsights/workspaces/DefaultWorkspace-6d5a4a5c-4ba5-450e-ab55-a6e4dabfa9a4-SEA"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
    # admin_group_object_ids = [azuread_group.aks_admins.object_id]  # requires AD admin to create groups
  }
}