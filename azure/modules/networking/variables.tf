variable "project_name"     { type = string }
variable "location"         { type = string }
variable "vnet_cidr"        { type = string }
variable "web_subnet_cidrs" { type = list(string) }
variable "app_subnet_cidrs" { type = list(string) }
variable "db_subnet_cidrs"  { type = list(string) }
