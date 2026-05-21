variable "project_name"     { type = string }
variable "instance_type"    { type = string }
variable "key_name"         { type = string }
variable "web_subnet_id"    { type = string }
variable "app_subnet_id"    { type = string }
variable "web_sg_id"        { type = string }
variable "app_sg_id"        { type = string }
variable "internal_alb_dns" { type = string }
variable "public_alb_dns"   { type = string }
variable "db_host"          { type = string }
variable "db_name"          { type = string }
variable "db_username"      { type = string }
variable "db_password"      { type = string; sensitive = true }
variable "jwt_secret"       { type = string; sensitive = true }
