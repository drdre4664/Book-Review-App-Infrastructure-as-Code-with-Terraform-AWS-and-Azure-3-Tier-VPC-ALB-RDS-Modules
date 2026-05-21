variable "project_name"       { type = string }
variable "aws_region"         { type = string; default = "us-east-1" }
variable "vpc_cidr"           { type = string; default = "10.0.0.0/16" }
variable "availability_zones" { type = list(string) }
variable "web_subnet_cidrs"   { type = list(string) }
variable "app_subnet_cidrs"   { type = list(string) }
variable "db_subnet_cidrs"    { type = list(string) }
variable "instance_type"      { type = string; default = "t2.micro" }
variable "key_name"           { type = string }
variable "db_instance_class"  { type = string; default = "db.t3.micro" }
variable "db_name"            { type = string }
variable "db_username"        { type = string }
variable "db_password"        { type = string; sensitive = true }
variable "jwt_secret"         { type = string; sensitive = true }
