# Requirement: Production Environment Configuration
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
# Description: Configures production environment identifier
environment = "prod"

# Requirement: High Availability
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
# Description: Sets primary AWS region with multi-AZ support
region = "us-east-1"

# Requirement: Security Controls
# Location: 5. SECURITY CONSIDERATIONS/5.3.1 Network Security
# Description: Defines production VPC CIDR with sufficient address space
vpc_cidr = "10.0.0.0/16"

# Requirement: High Availability
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
# Description: Configures three availability zones for redundancy
availability_zones = [
  "us-east-1a",
  "us-east-1b",
  "us-east-1c"
]

# Requirement: Production Environment Configuration
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
# Description: Configures production-grade RDS instance with memory optimization
db_instance_class = "db.r6g.xlarge"

# Requirement: Production Environment Configuration
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
# Description: Sets production ECS instance type for container workloads
ecs_instance_type = "t3.large"

# Requirement: Production Environment Configuration
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
# Description: Configures production Redis cache with memory-optimized instances
redis_node_type = "cache.r6g.large"

# Requirement: High Availability
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
# Description: Enables multi-AZ deployment for high availability
multi_az = true

# Requirement: Security Controls
# Location: 5. SECURITY CONSIDERATIONS/5.3.1 Network Security
# Description: Sets production-compliant backup retention period
backup_retention_days = 30

# Requirement: Production Environment Configuration
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
# Description: Defines comprehensive production environment tags
tags = {
  Environment   = "prod"
  Project       = "Founditure"
  ManagedBy     = "Terraform"
  CostCenter    = "Production"
  BackupPolicy  = "Daily"
  SecurityLevel = "High"
}