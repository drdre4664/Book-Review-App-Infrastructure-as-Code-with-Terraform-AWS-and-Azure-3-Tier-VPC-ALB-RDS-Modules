# Public Load Balancer
resource "azurerm_public_ip" "web" {
  name                = "${var.project_name}-web-lb-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "public" {
  name                = "${var.project_name}-public-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "web-frontend"
    public_ip_address_id = azurerm_public_ip.web.id
  }
}

resource "azurerm_lb_backend_address_pool" "web" {
  name            = "${var.project_name}-web-backend-pool"
  loadbalancer_id = azurerm_lb.public.id
}

resource "azurerm_lb_probe" "web" {
  name            = "web-health-probe"
  loadbalancer_id = azurerm_lb.public.id
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

resource "azurerm_lb_rule" "web" {
  name                           = "web-lb-rule"
  loadbalancer_id                = azurerm_lb.public.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "web-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web.id]
  probe_id                       = azurerm_lb_probe.web.id
}

# Internal Load Balancer
resource "azurerm_lb" "internal" {
  name                = "${var.project_name}-internal-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "app-frontend"
    subnet_id                     = var.app_subnet_id
    private_ip_address            = "10.0.3.10"
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb_backend_address_pool" "app" {
  name            = "${var.project_name}-app-backend-pool"
  loadbalancer_id = azurerm_lb.internal.id
}

resource "azurerm_lb_probe" "app" {
  name            = "app-health-probe"
  loadbalancer_id = azurerm_lb.internal.id
  protocol        = "Http"
  port            = 3001
  request_path    = "/health"
}

resource "azurerm_lb_rule" "app" {
  name                           = "app-lb-rule"
  loadbalancer_id                = azurerm_lb.internal.id
  protocol                       = "Tcp"
  frontend_port                  = 3001
  backend_port                   = 3001
  frontend_ip_configuration_name = "app-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app.id]
  probe_id                       = azurerm_lb_probe.app.id
}
