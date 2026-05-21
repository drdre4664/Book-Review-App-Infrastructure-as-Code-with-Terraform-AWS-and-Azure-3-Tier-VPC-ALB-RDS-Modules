resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.db_subnet_ids
  tags       = { Name = "${var.project_name}-db-subnet-group" }
}

resource "aws_db_instance" "primary" {
  identifier             = "${var.project_name}-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]
  multi_az               = true
  publicly_accessible    = false
  skip_final_snapshot    = true
  tags                   = { Name = "${var.project_name}-db-primary" }
}

resource "aws_db_instance" "replica" {
  identifier          = "${var.project_name}-db-replica"
  replicate_source_db = aws_db_instance.primary.identifier
  instance_class      = var.db_instance_class
  publicly_accessible = false
  skip_final_snapshot = true
  tags                = { Name = "${var.project_name}-db-replica" }
}
