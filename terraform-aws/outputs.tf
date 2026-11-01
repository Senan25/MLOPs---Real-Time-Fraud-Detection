
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.ml_api.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.ml_api.arn
}

output "rds_endpoint" {
  description = "Private PostgreSQL endpoint"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "PostgreSQL port"
  value       = aws_db_instance.postgres.port
}

output "rds_database_name" {
  value = aws_db_instance.postgres.db_name
}

output "rds_master_secret_arn" {
  description = "Secrets Manager ARN for the RDS master password"
  value       = aws_db_instance.postgres.master_user_secret[0].secret_arn
}
