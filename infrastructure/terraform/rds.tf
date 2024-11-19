# Human Tasks:
# 1. Store database credentials securely in AWS Secrets Manager
# 2. Review and adjust PostgreSQL parameter group settings based on workload
# 3. Verify backup window and maintenance window align with business requirements
# 4. Ensure monitoring IAM role exists for Enhanced Monitoring
# 5. Review storage allocation and scaling thresholds

# AWS Provider version ~> 5.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data sources for VPC and subnet information
data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "subnet-id"
    values = var.private_subnet_ids
  }
}

# Requirement: Database Infrastructure
# Location: 6. INFRASTRUCTURE/6.2 Cloud Services/AWS Service Stack
resource "aws_db_subnet_group" "main" {
  name        = "${var.environment}-founditure-db-subnet-group"
  description = "Database subnet group for Founditure ${var.environment} environment"
  subnet_ids  = data.aws_subnets.private.ids

  tags = {
    Name        = "founditure-${var.environment}-db-subnet-group"
    Environment = var.environment
  }
}

# Requirement: Data Security
# Location: 5. SECURITY CONSIDERATIONS/5.2 Data Security/Encryption Standards
resource "aws_security_group" "db" {
  name        = "${var.environment}-founditure-db-sg"
  description = "Security group for Founditure RDS instance"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "PostgreSQL access from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "founditure-${var.environment}-db-sg"
    Environment = var.environment
  }
}

# Requirement: High Availability
# Location: 6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
resource "aws_db_parameter_group" "postgres15" {
  name        = "${var.environment}-founditure-postgres15"
  family      = "postgres15"
  description = "Custom parameter group for Founditure PostgreSQL 15"

  parameter {
    name  = "max_connections"
    value = "1000"
  }

  parameter {
    name  = "shared_buffers"
    value = "{DBInstanceClassMemory/4}"
  }

  parameter {
    name  = "work_mem"
    value = "64000"
  }

  parameter {
    name  = "maintenance_work_mem"
    value = "128000"
  }

  parameter {
    name  = "effective_cache_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  tags = {
    Name        = "founditure-${var.environment}-pg15"
    Environment = var.environment
  }
}

# Requirement: Database Infrastructure
# Location: 6. INFRASTRUCTURE/6.2 Cloud Services/AWS Service Stack
resource "aws_db_instance" "main" {
  identifier     = "${var.environment}-founditure-postgres"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.db_instance_class

  # Storage configuration
  allocated_storage     = 100
  max_allocated_storage = 1000
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database configuration
  db_name  = "founditure"
  username = "founditure_admin"
  # Password should be managed through AWS Secrets Manager
  
  # High availability configuration
  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  # Backup configuration
  backup_retention_period = var.backup_retention_days
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"
  
  # Deletion protection
  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.environment}-founditure-final-snapshot"

  # Performance and monitoring
  parameter_group_name                  = aws_db_parameter_group.postgres15.name
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  monitoring_interval                   = 60
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]

  # Additional configurations
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot     = true

  tags = {
    Name        = "founditure-${var.environment}-rds"
    Environment = var.environment
  }
}

# Outputs for use in other modules
output "rds_endpoint" {
  description = "Connection endpoint for the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "Port number for database connections"
  value       = aws_db_instance.main.port
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.db.id
}