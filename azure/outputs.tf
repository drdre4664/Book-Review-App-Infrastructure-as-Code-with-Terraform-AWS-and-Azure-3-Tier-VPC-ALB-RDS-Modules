output "public_lb_ip" {
  description = "Public URL to access the application"
  value       = "http://${module.load_balancer.public_lb_ip}"
}
output "internal_lb_ip" {
  value = module.load_balancer.internal_lb_ip
}
output "mysql_host" {
  value = module.database.mysql_host
}
output "resource_group" {
  value = module.networking.resource_group_name
}
