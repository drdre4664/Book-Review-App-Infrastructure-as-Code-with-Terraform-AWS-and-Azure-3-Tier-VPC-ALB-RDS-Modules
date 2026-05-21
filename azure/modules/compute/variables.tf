variable "project_name"        { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "web_subnet_id"       { type = string }
variable "app_subnet_id"       { type = string }
variable "web_nsg_id"          { type = string }
variable "app_nsg_id"          { type = string }
variable "vm_size"             { type = string }
variable "admin_username"      { type = string }
variable "internal_lb_ip"      { type = string }
variable "public_lb_ip"        { type = string }
variable "mysql_host"          { type = string }
variable "db_name"             { type = string }
variable "db_admin"            { type = string }
variable "db_password"         { type = string; sensitive = true }
variable "jwt_secret"          { type = string; sensitive = true }
