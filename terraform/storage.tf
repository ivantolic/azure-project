resource "random_string" "storage_suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_storage_account" "main" {
  name                     = "stitolic${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = [replace(var.admin_ip_cidr, "/32", "")]
    virtual_network_subnet_ids = [
      azurerm_subnet.aks_subnet.id,
      azurerm_subnet.function_subnet.id,
      azurerm_subnet.jump_subnet.id,
      azurerm_subnet.private_endpoints_subnet.id
    ]
  }

  tags = var.common_tags
}

resource "azurerm_storage_container" "app_container" {
  name                  = "appdata"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

resource "azurerm_storage_share" "onprem_share" {
  name               = "onpremfiles"
  storage_account_id = azurerm_storage_account.main.id
  quota              = 10
}

resource "azurerm_role_assignment" "app_identity_blob_contributor" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.app_identity.principal_id
}

resource "azurerm_role_assignment" "app_identity_file_share_contributor" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = azurerm_user_assigned_identity.app_identity.principal_id
}