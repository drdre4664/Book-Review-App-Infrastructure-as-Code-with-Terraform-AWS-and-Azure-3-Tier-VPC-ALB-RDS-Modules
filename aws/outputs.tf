output "public_alb_dns" {
  description = "Public URL to access the application"
  value       = "http://${module.load_balancer.public_alb_dns}"
}
output "internal_alb_dns" {
  value = module.load_balancer.internal_alb_dns
}
output "rds_endpoint" {
  value = module.database.db_endpoint
}
output "vpc_id" {
  value = module.networking.vpc_id
}
