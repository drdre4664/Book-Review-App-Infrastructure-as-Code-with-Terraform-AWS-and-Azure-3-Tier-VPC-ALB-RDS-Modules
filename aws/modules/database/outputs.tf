output "db_endpoint" { value = aws_db_instance.primary.address }
output "db_name"     { value = aws_db_instance.primary.db_name }
