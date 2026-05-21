variable "project_name"    { type = string }
variable "location"        { type = string; default = "East US" }
variable "vnet_cidr"       { type = string; default = "10.0.0.0/16" }
variable "web_subnet_cidrs" { type = list(string) }
variable "app_subnet_cidrs" { type = list(string) }
variable "db_subnet_cidrs"  { type = list(string) }
variable "vm_size"          { type = string; default = "Standard_B1s" }
variable "admin_username"   { type = string; default = "azureuser" }
variable "db_name"          { type = string }
variable "db_admin"         { type = string }
variable "db_password"      { type = string; sensitive = true }
variable "jwt_secret"       { type = string; sensitive = true }
