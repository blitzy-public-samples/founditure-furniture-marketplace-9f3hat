# Human Tasks:
# 1. Verify MongoDB Atlas project ID is correctly configured for your organization
# 2. Review RDS instance class selection based on workload requirements
# 3. Adjust backup retention period according to data retention policies
# 4. Evaluate Multi-AZ deployment requirements for each environment
# 5. Confirm encryption requirements align with security policies

# Requirement: Database Infrastructure (6.2 Cloud Services)
# Environment configuration for database deployment
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod"
  }
}

# Requirement: Database Infrastructure (6.2 Cloud Services)
# VPC configuration for database resources
variable "vpc_id" {
  description = "ID of the VPC where database resources will be deployed"
  type        = string
}

# Requirement: Data Security (5.2 Data Security)
# Network security configuration
variable "vpc_cidr" {
  description = "CIDR block of the VPC for security group rules"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block"
  }
}

# Requirement: High Availability (6.1 DEPLOYMENT ENVIRONMENT)
# Subnet configuration for high availability
variable "private_subnet_ids" {
  description = "List of private subnet IDs for database subnet group"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least two private subnets are required for high availability"
  }
}

# Requirement: Database Infrastructure (6.2 Cloud Services)
# RDS instance configuration
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"

  validation {
    condition     = can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.db_instance_class))
    error_message = "Invalid RDS instance class format"
  }
}

# Requirement: High Availability (6.1 DEPLOYMENT ENVIRONMENT)
# High availability configuration for RDS
variable "multi_az_enabled" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

# Requirement: Data Security (5.2 Data Security)
# Encryption configuration for RDS storage
variable "storage_encrypted" {
  description = "Enable storage encryption for RDS"
  type        = bool
  default     = true
}

# Requirement: Data Security (5.2 Data Security)
# Backup configuration for disaster recovery
variable "backup_retention_days" {
  description = "Number of days to retain RDS backups"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Backup retention period must be between 1 and 35 days"
  }
}

# Requirement: Database Infrastructure (6.2 Cloud Services)
# Performance monitoring configuration
variable "performance_insights_enabled" {
  description = "Enable Performance Insights for RDS"
  type        = bool
  default     = false
}

# Requirement: Database Infrastructure (6.2 Cloud Services)
# MongoDB Atlas configuration
variable "mongodb_project_id" {
  description = "MongoDB Atlas project ID"
  type        = string
}

# Requirement: Database Infrastructure (6.2 Cloud Services)
# MongoDB Atlas instance sizing
variable "mongodb_instance_size" {
  description = "MongoDB Atlas instance size"
  type        = string
  default     = "M10"

  validation {
    condition     = can(regex("^M[0-9]+$", var.mongodb_instance_size))
    error_message = "Invalid MongoDB Atlas instance size format"
  }
}