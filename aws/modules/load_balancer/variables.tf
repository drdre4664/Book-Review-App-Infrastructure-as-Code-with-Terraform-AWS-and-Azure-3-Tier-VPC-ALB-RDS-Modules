variable "project_name"       { type = string }
variable "vpc_id"             { type = string }
variable "web_subnet_ids"     { type = list(string) }
variable "app_subnet_ids"     { type = list(string) }
variable "alb_public_sg_id"   { type = string }
variable "alb_internal_sg_id" { type = string }
