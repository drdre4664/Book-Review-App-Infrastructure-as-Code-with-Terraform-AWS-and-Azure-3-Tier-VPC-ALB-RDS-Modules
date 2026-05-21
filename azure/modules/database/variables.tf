variable "project_name"        { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "db_subnet_id"        { type = string }
variable "vnet_id"             { type = string }
variable "db_name"             { type = string }
variable "db_admin"            { type = string }
variable "db_password"         { type = string; sensitive = true }
