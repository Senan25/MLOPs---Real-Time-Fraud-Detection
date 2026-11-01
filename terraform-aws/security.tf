
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "PostgreSQL access from approved private networks"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.allowed_db_cidr_blocks

    content {
      description = "PostgreSQL from approved CIDR"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}
