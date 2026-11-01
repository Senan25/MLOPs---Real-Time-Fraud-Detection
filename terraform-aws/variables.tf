
variable "aws_region" {
  description = "AWS deployment region"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "fraud-detection"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "frauddb"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "dbadmin"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS storage in GiB"
  type        = number
  default     = 20
}

variable "allowed_db_cidr_blocks" {
  description = "Approved IPv4 CIDRs allowed to access PostgreSQL"
  type        = list(string)
  default     = []
}
