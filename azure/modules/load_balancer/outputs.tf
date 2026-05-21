output "public_lb_ip"        { value = azurerm_public_ip.web.ip_address }
output "internal_lb_ip"      { value = azurerm_lb.internal.private_ip_address }
output "web_backend_pool_id" { value = azurerm_lb_backend_address_pool.web.id }
output "app_backend_pool_id" { value = azurerm_lb_backend_address_pool.app.id }
