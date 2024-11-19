# AWS Provider version: ~> 4.0
# MongoDB Atlas Provider version: ~> 1.0

# Human Tasks:
# 1. Configure AWS provider with appropriate credentials and region
# 2. Set up MongoDB Atlas provider with organization API key
# 3. Review and adjust RDS parameter group settings if needed
# 4. Verify MongoDB Atlas network access configuration
# 5. Ensure backup windows align with operational requirements

# Required provider configurations
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 1.0"
    }
  }
}

# Requirement: Database Infrastructure (6.2 Cloud Services)
# Create DB subnet group for RDS instance placement
resource "aws_db_subnet_group" "main" {
  name        = "${var.environment}-founditure-db-subnet-group"
  subnet_ids  = var.private_subnet_ids
  description = "Database subnet group for ${var.environment} environment"

  tags = {
    Environment = var.environment
    Project     = "founditure"
    Terraform   = "true"
  }
}

# Requirement: Data Security (5.2 Data Security)
# Security group for database access control
resource "aws_security_group" "main" {
  name        = "${var.environment}-founditure-db-sg"
  description = "Security group for ${var.environment} database resources"
  vpc_id      = var.vpc_id

  # PostgreSQL ingress rule
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow PostgreSQL access from VPC"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Environment = var.environment
    Project     = "founditure"
    Terraform   = "true"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Requirement: Database Infrastructure (6.2 Cloud Services)
# RDS PostgreSQL instance for structured data
resource "aws_db_instance" "main" {
  identifier = "${var.environment}-founditure-postgres"
  
  # Engine configuration
  engine         = "postgres"
  engine_version = "14"
  
  # Instance configuration
  instance_class        = var.db_instance_class
  allocated_storage     = 20
  max_allocated_storage = 100
  
  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.main.id]
  
  # Requirement: High Availability (6.1 DEPLOYMENT ENVIRONMENT)
  multi_az = var.multi_az_enabled
  
  # Requirement: Data Security (5.2 Data Security)
  storage_encrypted        = var.storage_encrypted
  backup_retention_period = var.backup_retention_days
  
  # Performance and monitoring
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval         = 60
  monitoring_role_arn        = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/rds-monitoring-role"
  
  # Protection settings
  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.environment}-founditure-postgres-final"
  
  # Maintenance settings
  auto_minor_version_upgrade = true
  maintenance_window        = "Mon:03:00-Mon:04:00"
  backup_window            = "02:00-03:00"
  
  tags = {
    Environment = var.environment
    Project     = "founditure"
    Terraform   = "true"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Get current AWS account ID for resource ARNs
data "aws_caller_identity" "current" {}

# Requirement: Database Infrastructure (6.2 Cloud Services)
# MongoDB Atlas cluster for document storage
resource "mongodbatlas_cluster" "main" {
  project_id = var.mongodb_project_id
  name       = "${var.environment}-founditure-mongodb"
  
  # Cluster configuration
  cluster_type = "REPLICASET"
  
  # Cloud provider settings
  provider_name               = "AWS"
  provider_region_name        = "US_EAST_1"
  provider_instance_size_name = var.mongodb_instance_size
  
  # MongoDB version
  mongo_db_major_version = "6.0"
  
  # Requirement: Data Security (5.2 Data Security)
  backup_enabled = true
  pit_enabled    = var.environment == "prod"
  
  # Storage configuration
  auto_scaling_disk_gb_enabled = true
  
  # Requirement: High Availability (6.1 DEPLOYMENT ENVIRONMENT)
  replication_specs {
    num_shards = 1
    regions_config {
      region_name     = "US_EAST_1"
      electable_nodes = 3
      priority        = 7
      read_only_nodes = 0
    }
  }

  advanced_configuration {
    javascript_enabled                   = false
    minimum_enabled_tls_protocol        = "TLS1_2"
    no_table_scan                       = false
    oplog_size_mb                       = 1024
    sample_size_bi_connector           = 1000
    sample_refresh_interval_bi_connector = 300
  }
}

# Output definitions for RDS instance
output "rds_instance" {
  value = {
    endpoint = aws_db_instance.main.endpoint
    address  = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    id       = aws_db_instance.main.id
    arn      = aws_db_instance.main.arn
  }
  description = "RDS instance connection details"
}

# Output definitions for MongoDB cluster
output "mongodb_cluster" {
  value = {
    connection_strings  = mongodbatlas_cluster.main.connection_strings
    cluster_id         = mongodbatlas_cluster.main.cluster_id
    mongo_uri          = mongodbatlas_cluster.main.mongo_uri
    mongo_uri_updated  = mongodbatlas_cluster.main.mongo_uri_updated
  }
  description = "MongoDB Atlas cluster connection details"
}

# Output definitions for security group
output "security_group" {
  value = {
    id   = aws_security_group.main.id
    name = aws_security_group.main.name
    arn  = aws_security_group.main.arn
  }
  description = "Security group details for database access"
}