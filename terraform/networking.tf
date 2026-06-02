resource "azurerm_virtual_network" "private_vnet" {
  name                = "vnet-private-itolic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.10.0.0/16"]

  tags = var.common_tags
}

resource "azurerm_virtual_network" "jump_vnet" {
  name                = "vnet-jump-itolic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.20.0.0/16"]

  tags = var.common_tags
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.private_vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "postgres_subnet" {
  name                 = "snet-postgresql"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.private_vnet.name
  address_prefixes     = ["10.10.2.0/24"]

  delegation {
    name = "postgresql-delegation"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

resource "azurerm_subnet" "function_subnet" {
  name                 = "snet-function"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.private_vnet.name
  address_prefixes     = ["10.10.3.0/24"]

  delegation {
    name = "function-delegation"

    service_delegation {
      name = "Microsoft.Web/serverFarms"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

resource "azurerm_subnet" "appgw_subnet" {
  name                 = "snet-appgateway"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.private_vnet.name
  address_prefixes     = ["10.10.4.0/24"]
}

resource "azurerm_subnet" "private_endpoints_subnet" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.private_vnet.name
  address_prefixes     = ["10.10.5.0/24"]
}

resource "azurerm_subnet" "jump_subnet" {
  name                 = "snet-jump"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.jump_vnet.name
  address_prefixes     = ["10.20.1.0/24"]
}

resource "azurerm_virtual_network_peering" "jump_to_private" {
  name                      = "peer-jump-to-private"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.jump_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.private_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "private_to_jump" {
  name                      = "peer-private-to-jump"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.private_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.jump_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}