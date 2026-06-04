data "azurerm_client_config" "current" {}

resource "random_string" "key_vault_suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "random_password" "postgres_admin_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_user_assigned_identity" "app_identity" {
  name                = "id-app-itolic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.common_tags
}

resource "azurerm_user_assigned_identity" "appgw_identity" {
  name                = "id-appgw-itolic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.common_tags
}

resource "azurerm_key_vault" "main" {
  name                = "kv-itolic-${random_string.key_vault_suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  rbac_authorization_enabled = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  public_network_access_enabled = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"

    ip_rules = [
      var.admin_ip_cidr
    ]

    virtual_network_subnet_ids = [
      azurerm_subnet.jump_subnet.id
    ]
  }

  tags = var.common_tags
}

resource "azurerm_role_assignment" "current_user_key_vault_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "app_identity_key_vault_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app_identity.principal_id
}

resource "azurerm_role_assignment" "appgw_identity_key_vault_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.appgw_identity.principal_id
}

resource "time_sleep" "wait_for_key_vault_rbac" {
  depends_on = [
    azurerm_role_assignment.current_user_key_vault_secrets_officer
  ]

  create_duration = "60s"
}

resource "azurerm_key_vault_secret" "postgres_admin_password" {
  name         = "postgres-admin-password"
  value        = random_password.postgres_admin_password.result
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    time_sleep.wait_for_key_vault_rbac
  ]

  tags = var.common_tags
}