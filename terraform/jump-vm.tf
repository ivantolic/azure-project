resource "random_password" "jump_vm_admin_password" {
  length  = 20
  special = false
}

resource "azurerm_key_vault_secret" "jump_vm_admin_password" {
  name         = "jump-vm-admin-password"
  value        = random_password.jump_vm_admin_password.result
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    time_sleep.wait_for_key_vault_rbac
  ]

  tags = var.common_tags
}

resource "azurerm_public_ip" "jump_vm_pip" {
  name                = "pip-jump-itolic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  allocation_method = "Static"
  sku               = "Standard"

  tags = var.common_tags
}

resource "azurerm_network_security_group" "jump_nsg" {
  name                = "nsg-jump-itolic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-RDP-From-Admin-IP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.admin_ip_cidr
    destination_address_prefix = "*"
  }

  tags = var.common_tags
}

resource "azurerm_subnet_network_security_group_association" "jump_subnet_nsg" {
  subnet_id                 = azurerm_subnet.jump_subnet.id
  network_security_group_id = azurerm_network_security_group.jump_nsg.id
}

resource "azurerm_network_interface" "jump_vm_nic" {
  name                = "nic-jump-itolic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig-jump"
    subnet_id                     = azurerm_subnet.jump_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jump_vm_pip.id
  }

  tags = var.common_tags
}

resource "azurerm_windows_virtual_machine" "jump_vm" {
  name                = "vm-jump-itolic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  size           = "Standard_B1s"
  admin_username = "azureadmin"
  admin_password = random_password.jump_vm_admin_password.result

  network_interface_ids = [
    azurerm_network_interface.jump_vm_nic.id
  ]

  provision_vm_agent        = true
  automatic_updates_enabled = true
  patch_mode                = "AutomaticByPlatform"

  os_disk {
    name                 = "osdisk-jump-itolic"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 127
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  tags = var.common_tags
}