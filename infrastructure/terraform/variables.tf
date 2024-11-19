# Human Tasks:
# 1. Ensure AWS credentials are properly configured for the target AWS account
# 2. Verify that the specified AWS regions are enabled for your account
# 3. Review and adjust the CIDR blocks according to your network design requirements
# 4. Confirm that the selected instance types are available in your target regions
# 5. Validate that the availability zones specified are available in your regions

# Requirement: Multi-Environment Infrastructure
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
variable "environment" {
  description = "Deployment environment identifier (dev/staging/prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

# Requirement: AWS Service Configuration
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.region))
    error_message = "Region must be a valid AWS region identifier (e.g., us-east-1)"
  }
}

# Requirement: Multi-Environment Infrastructure
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block"
  }
}

# Requirement: AWS Service Configuration
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
variable "availability_zones" {
  description = "List of availability zones for multi-AZ deployment"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones must be specified for high availability"
  }
}

# Requirement: AWS Service Configuration
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
variable "db_instance_class" {
  description = "RDS instance type based on environment"
  type        = string
  default     = "db.t3.medium"

  validation {
    condition     = can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.db_instance_class))
    error_message = "DB instance class must be a valid RDS instance type"
  }
}

# Requirement: AWS Service Configuration
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
variable "ecs_instance_type" {
  description = "ECS container instance type"
  type        = string
  default     = "t3.medium"

  validation {
    condition     = can(regex("^[a-z0-9]+\\.[a-z0-9]+$", var.ecs_instance_type))
    error_message = "ECS instance type must be a valid EC2 instance type"
  }
}

# Requirement: AWS Service Configuration
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.medium"

  validation {
    condition     = can(regex("^cache\\.[a-z0-9]+\\.[a-z0-9]+$", var.redis_node_type))
    error_message = "Redis node type must be a valid ElastiCache node type"
  }
}

# Requirement: Multi-Environment Infrastructure
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
variable "multi_az" {
  description = "Enable/disable multi-AZ deployment"
  type        = bool
  default     = false
}

# Requirement: Security Controls
# Location: 5. SECURITY CONSIDERATIONS/5.1 AUTHENTICATION AND AUTHORIZATION
variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Backup retention days must be between 1 and 35"
  }
}

# Requirement: Multi-Environment Infrastructure
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
variable "tags" {
  description = "Resource tags for cost allocation and management"
  type        = map(string)
  default = {
    Project   = "Founditure"
    ManagedBy = "Terraform"
  }

  validation {
    condition     = length(var.tags) > 0
    error_message = "At least one tag must be specified"
  }
}