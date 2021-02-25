resource "azurerm_virtual_machine_extension" "azure_monitor_agent" {
  name = "${azurerm_linux_virtual_machine.vm.name}-azmonitorextension"

  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = "true"

  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
}

resource "null_resource" "azure_monitor_link" {
  provisioner "local-exec" {
    command = <<EOC
      az rest --subscription ${data.azurerm_client_config.current.subscription_id} \
              --method PUT \
              --url https://management.azure.com${azurerm_linux_virtual_machine.vm.id}/providers/Microsoft.Insights/dataCollectionRuleAssociations/${azurerm_linux_virtual_machine.vm.name}-dcrassociation?api-version=2019-11-01-preview \
              --body '{"properties":{"dataCollectionRuleId": "${var.azure_monitor_data_collection_rule_id}"}}'
EOC
  }

  triggers = {
    dcr_id = var.azure_monitor_data_collection_rule_id
    vm_id  = azurerm_linux_virtual_machine.vm.id
  }
}
