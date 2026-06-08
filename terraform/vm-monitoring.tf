resource "azurerm_monitor_data_collection_rule" "vm_windows_security_logs" {
  name                = "dcr-vm-security-logs-itolic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "Windows"

  destinations {
    log_analytics {
      name                  = "law-destination"
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
    }
  }

  data_flow {
    streams      = ["Microsoft-Event"]
    destinations = ["law-destination"]
  }

  data_sources {
    windows_event_log {
      name    = "windows-security-events"
      streams = ["Microsoft-Event"]

      x_path_queries = [
        "Security!*[System[(Level=0 or Level=1 or Level=2 or Level=3 or Level=4)]]",
        "System!*[System[(Level=0 or Level=1 or Level=2 or Level=3 or Level=4)]]",
        "Application!*[System[(Level=0 or Level=1 or Level=2 or Level=3 or Level=4)]]"
      ]
    }
  }

  tags = var.common_tags
}

resource "azurerm_virtual_machine_extension" "jump_vm_ama" {
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.jump_vm.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.42"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true

  tags = var.common_tags
}

resource "azurerm_monitor_data_collection_rule_association" "jump_vm_security_logs" {
  name                    = "dcra-jump-vm-security-logs"
  target_resource_id      = azurerm_windows_virtual_machine.jump_vm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_windows_security_logs.id

  depends_on = [
    azurerm_virtual_machine_extension.jump_vm_ama
  ]
}
resource "azurerm_log_analytics_datasource_windows_event" "application_events" {
  name                = "collect-application-events"
  resource_group_name = azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.main.name

  event_log_name = "Application"
  event_types    = ["Information", "Warning", "Error"]
}

resource "azurerm_log_analytics_datasource_windows_event" "system_events" {
  name                = "collect-system-events"
  resource_group_name = azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.main.name

  event_log_name = "System"
  event_types    = ["Information", "Warning", "Error"]
}