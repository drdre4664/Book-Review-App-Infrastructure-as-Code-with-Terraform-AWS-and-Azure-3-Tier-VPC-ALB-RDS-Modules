output "resource_group_name" { value = azurerm_resource_group.main.name }
output "vnet_id"             { value = azurerm_virtual_network.main.id }
output "web_subnet_ids"      { value = azurerm_subnet.web[*].id }
output "app_subnet_ids"      { value = azurerm_subnet.app[*].id }
output "db_subnet_ids"       { value = azurerm_subnet.db[*].id }
output "web_nsg_id"          { value = azurerm_network_security_group.web.id }
output "app_nsg_id"          { value = azurerm_network_security_group.app.id }
