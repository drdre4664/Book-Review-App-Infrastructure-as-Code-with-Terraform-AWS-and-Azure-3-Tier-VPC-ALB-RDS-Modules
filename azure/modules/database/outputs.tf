output "mysql_host" { value = azurerm_mysql_flexible_server.primary.fqdn }
output "db_name"    { value = azurerm_mysql_flexible_database.main.name }
