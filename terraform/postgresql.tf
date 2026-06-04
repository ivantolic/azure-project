resource "random_string" "postgres_suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name

  tags = var.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres_private_vnet_link" {
  name                  = "pdnslink-postgres-private-vnet"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.private_vnet.id
  registration_enabled  = false

  tags = var.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres_jump_vnet_link" {
  name                  = "pdnslink-postgres-jump-vnet"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.jump_vnet.id
  registration_enabled  = false

  tags = var.common_tags
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                = "psql-itolic-${random_string.postgres_suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  zone                = "1"

  version = "16"

  administrator_login    = "pgadminitolic"
  administrator_password = random_password.postgres_admin_password.result

  delegated_subnet_id = azurerm_subnet.postgres_subnet.id
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id

  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  public_network_access_enabled = false

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres_private_vnet_link,
    azurerm_private_dns_zone_virtual_network_link.postgres_jump_vnet_link
  ]

  tags = var.common_tags
}

resource "azurerm_postgresql_flexible_server_database" "appdb" {
  name      = "appdb"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}