# --- Azure Key Vault ---

resource "azurerm_key_vault" "main" {
  name                = var.keyvault_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  rbac_authorization_enabled  = true
}

# Let current user manage secrets in the vault
resource "azurerm_role_assignment" "keyvault_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# --- Workload Identity for External Secrets Operator ---

# Managed Identity that External Secrets Operator will use
resource "azurerm_user_assigned_identity" "external_secrets" {
  name                = "id-proj-externalsecrets"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Let the managed identity read secrets from Key Vault
resource "azurerm_role_assignment" "external_secrets_keyvault" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.external_secrets.principal_id
}

# Federated credential — links K8s service account to the managed identity
resource "azurerm_federated_identity_credential" "external_secrets" {
  name                = "external-secrets-fed-cred"
  resource_group_name = azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.external_secrets.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject             = "system:serviceaccount:external-secrets:external-secrets"
}

# --- A demo secret to test with ---

resource "azurerm_key_vault_secret" "demo" {
  name         = "proj-api-key"
  value        = "placeholder-value"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.keyvault_admin]
}
