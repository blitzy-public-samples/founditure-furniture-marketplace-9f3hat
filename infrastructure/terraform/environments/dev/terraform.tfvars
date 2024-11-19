# Requirement: Development Environment Configuration
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
# Development environment identifier
environment = "dev"

# Primary AWS region for development resources
region = "us-east-1"

# CIDR block for development VPC
vpc_cidr = "10.0.0.0/16"

# Requirement: Resource Optimization
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
# Development environment uses reduced AZ count for cost optimization
availability_zones = [
  "us-east-1a",
  "us-east-1b"
]

# Cost-effective instance sizes for development environment
db_instance_class = "db.t3.small"
ecs_instance_type = "t3.small"
redis_node_type = "cache.t3.small"

# Requirement: Security Controls
# Location: 5. SECURITY CONSIDERATIONS/5.2 DATA SECURITY
# Disable multi-AZ deployment for development cost savings
multi_az = false

# Reduced backup retention for development environment
backup_retention_days = 3

# Development environment resource tags
tags = {
  Environment = "development"
  Project     = "Founditure"
  ManagedBy   = "Terraform"
  Team        = "DevOps"
}