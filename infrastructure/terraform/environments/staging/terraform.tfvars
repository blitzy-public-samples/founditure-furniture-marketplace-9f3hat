# Requirement: Staging Environment Configuration
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
environment = "staging"

# Requirement: AWS Service Stack
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
region = "us-east-1"

# Requirement: Security Controls
# Location: 5. SECURITY CONSIDERATIONS/5.3.1 Network Security
vpc_cidr = "10.1.0.0/16"

# Requirement: Staging Environment Configuration
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
availability_zones = [
  "us-east-1a",
  "us-east-1b"
]

# Requirement: AWS Service Stack
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
db_instance_class = "db.t3.large"

# Requirement: AWS Service Stack
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
ecs_instance_type = "t3.large"

# Requirement: AWS Service Stack
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
redis_node_type = "cache.t3.medium"

# Requirement: Staging Environment Configuration
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
multi_az = true

# Requirement: Security Controls
# Location: 5. SECURITY CONSIDERATIONS/5.3.1 Network Security
backup_retention_days = 14

# Requirement: Staging Environment Configuration
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
tags = {
  Environment  = "staging"
  Project      = "Founditure"
  ManagedBy    = "Terraform"
  CostCenter   = "staging-infrastructure"
}