resource "aws_db_subnet_group" "main" {
  name = "${var.project_name}-db-subnet-group"

  # Keep the existing subnets currently used by RDS
  subnet_ids = [
    for subnet in aws_subnet.private : subnet.id
  ]

  description = "RDS subnets with Internet Gateway routing"

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-postgres"

  engine         = "postgres"
  instance_class = var.db_instance_class

  db_name  = var.db_name
  username = var.db_username
  port     = 5432

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = true
  multi_az            = false

  backup_retention_period    = 1
  auto_minor_version_upgrade = true

  performance_insights_enabled = false
  monitoring_interval          = 0

  deletion_protection = false
  skip_final_snapshot = true

  apply_immediately = true

  tags = {
    Name = "${var.project_name}-postgres"
  }
}