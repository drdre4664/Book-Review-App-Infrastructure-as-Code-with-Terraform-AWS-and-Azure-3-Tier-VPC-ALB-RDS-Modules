terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# -------------------------------------------------------
# Module 1 — Networking
# Creates: Resource Group, VNet, 6 subnets, NSGs
# -------------------------------------------------------
module "networking" {
  source           = "./modules/networking"
  project_name     = var.project_name
  location         = var.location
  vnet_cidr        = var.vnet_cidr
  web_subnet_cidrs = var.web_subnet_cidrs
  app_subnet_cidrs = var.app_subnet_cidrs
  db_subnet_cidrs  = var.db_subnet_cidrs
}

# -------------------------------------------------------
# Module 2 — Database
# Creates: Azure MySQL Flexible Server + Read Replica
# Depends on: networking (db_subnet_id, resource_group)
# -------------------------------------------------------
module "database" {
  source              = "./modules/database"
  project_name        = var.project_name
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  db_subnet_id        = module.networking.db_subnet_ids[0]
  vnet_id             = module.networking.vnet_id
  db_name             = var.db_name
  db_admin            = var.db_admin
  db_password         = var.db_password
}

# -------------------------------------------------------
# Module 3 — Load Balancer
# Creates: Public LB + Internal LB + backend pools
# Note: Backend pool associations done in root module
#       to break circular dependency with compute
# -------------------------------------------------------
module "load_balancer" {
  source              = "./modules/load_balancer"
  project_name        = var.project_name
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  web_subnet_id       = module.networking.web_subnet_ids[0]
  app_subnet_id       = module.networking.app_subnet_ids[0]
}

# -------------------------------------------------------
# Module 4 — Compute
# Creates: Web Tier VM + App Tier VM
# Depends on: database (mysql host for .env)
#             load_balancer (LB IPs for user_data)
# -------------------------------------------------------
module "compute" {
  source              = "./modules/compute"
  project_name        = var.project_name
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  web_subnet_id       = module.networking.web_subnet_ids[0]
  app_subnet_id       = module.networking.app_subnet_ids[0]
  web_nsg_id          = module.networking.web_nsg_id
  app_nsg_id          = module.networking.app_nsg_id
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  internal_lb_ip      = module.load_balancer.internal_lb_ip
  public_lb_ip        = module.load_balancer.public_lb_ip
  mysql_host          = module.database.mysql_host
  db_name             = var.db_name
  db_admin            = var.db_admin
  db_password         = var.db_password
  jwt_secret          = var.jwt_secret
  depends_on          = [module.database, module.load_balancer]
}

# -------------------------------------------------------
# Backend Pool Associations
# Placed in root to break circular dependency
# -------------------------------------------------------
resource "azurerm_network_interface_backend_address_pool_association" "web" {
  network_interface_id    = module.compute.web_nic_id
  ip_configuration_name   = "web-ip-config"
  backend_address_pool_id = module.load_balancer.web_backend_pool_id
}

resource "azurerm_network_interface_backend_address_pool_association" "app" {
  network_interface_id    = module.compute.app_nic_id
  ip_configuration_name   = "app-ip-config"
  backend_address_pool_id = module.load_balancer.app_backend_pool_id
}
