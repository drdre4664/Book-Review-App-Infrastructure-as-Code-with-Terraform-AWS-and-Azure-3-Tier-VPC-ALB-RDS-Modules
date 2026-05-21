resource "azurerm_private_dns_zone" "mysql" {
  name                = "${var.project_name}.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "${var.project_name}-mysql-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = var.vnet_id
}

# Primary MySQL Flexible Server — private VNet integration
resource "azurerm_mysql_flexible_server" "primary" {
  name                   = "${var.project_name}-mysql"
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.db_admin
  administrator_password = var.db_password
  sku_name               = "B_Standard_B1ms"
  version                = "8.0.21"
  delegated_subnet_id    = var.db_subnet_id
  private_dns_zone_id    = azurerm_private_dns_zone.mysql.id
  depends_on             = [azurerm_private_dns_zone_virtual_network_link.mysql]
}

resource "azurerm_mysql_flexible_database" "main" {
  name                = var.db_name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.primary.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# Read Replica
resource "azurerm_mysql_flexible_server" "replica" {
  name                   = "${var.project_name}-mysql-replica"
  resource_group_name    = var.resource_group_name
  location               = var.location
  create_mode            = "Replica"
  source_server_id       = azurerm_mysql_flexible_server.primary.id
  sku_name               = "B_Standard_B1ms"
}
