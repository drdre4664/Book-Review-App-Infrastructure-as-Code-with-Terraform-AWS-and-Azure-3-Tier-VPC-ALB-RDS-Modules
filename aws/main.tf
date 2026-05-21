terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -------------------------------------------------------
# Module 1 — Networking
# Creates: VPC, 6 subnets, IGW, NAT Gateway,
#          route tables, and all 5 security groups
# -------------------------------------------------------
module "networking" {
  source             = "./modules/networking"
  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  web_subnet_cidrs   = var.web_subnet_cidrs
  app_subnet_cidrs   = var.app_subnet_cidrs
  db_subnet_cidrs    = var.db_subnet_cidrs
  availability_zones = var.availability_zones
}

# -------------------------------------------------------
# Module 2 — Database
# Creates: RDS MySQL Multi-AZ + Read Replica
# Depends on: networking (db_subnet_ids, db_sg_id)
# -------------------------------------------------------
module "database" {
  source            = "./modules/database"
  project_name      = var.project_name
  db_subnet_ids     = module.networking.db_subnet_ids
  db_sg_id          = module.networking.db_sg_id
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  db_instance_class = var.db_instance_class
}

# -------------------------------------------------------
# Module 3 — Load Balancer
# Creates: Public ALB + Internal ALB + target groups
# Note: Target attachments are in root to break circular
#       dependency between compute and load_balancer
# -------------------------------------------------------
module "load_balancer" {
  source             = "./modules/load_balancer"
  project_name       = var.project_name
  vpc_id             = module.networking.vpc_id
  web_subnet_ids     = module.networking.web_subnet_ids
  app_subnet_ids     = module.networking.app_subnet_ids
  alb_public_sg_id   = module.networking.alb_public_sg_id
  alb_internal_sg_id = module.networking.alb_internal_sg_id
}

# -------------------------------------------------------
# Module 4 — Compute
# Creates: Web Tier EC2 (Nginx + Next.js)
#          App Tier EC2 (Node.js backend)
# Depends on: database (db endpoint for .env)
#             load_balancer (ALB DNS for user_data)
# -------------------------------------------------------
module "compute" {
  source           = "./modules/compute"
  project_name     = var.project_name
  instance_type    = var.instance_type
  key_name         = var.key_name
  web_subnet_id    = module.networking.web_subnet_ids[0]
  app_subnet_id    = module.networking.app_subnet_ids[0]
  web_sg_id        = module.networking.web_sg_id
  app_sg_id        = module.networking.app_sg_id
  internal_alb_dns = module.load_balancer.internal_alb_dns
  public_alb_dns   = module.load_balancer.public_alb_dns
  db_host          = module.database.db_endpoint
  db_name          = var.db_name
  db_username      = var.db_username
  db_password      = var.db_password
  jwt_secret       = var.jwt_secret
  depends_on       = [module.database, module.load_balancer]
}

# -------------------------------------------------------
# Target Group Attachments
# Placed in root to break circular dependency:
# - compute needs ALB DNS → load_balancer must exist first
# - attachments need instance IDs → compute must exist first
# -------------------------------------------------------
resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = module.load_balancer.web_tg_arn
  target_id        = module.compute.web_instance_id
  port             = 80
}

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = module.load_balancer.app_tg_arn
  target_id        = module.compute.app_instance_id
  port             = 3001
}
