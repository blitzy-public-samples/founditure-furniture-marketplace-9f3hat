# Human Tasks:
# 1. Ensure AWS KMS key is configured for encryption at rest
# 2. Review Redis auth token configuration in AWS Secrets Manager
# 3. Verify security group rules for Redis access
# 4. Validate backup window and maintenance window don't overlap with peak usage
# 5. Confirm Redis parameter group settings align with application requirements

# AWS Provider version ~> 5.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Requirement: Caching Layer
# Location: 6.2 CLOUD SERVICES/AWS Service Stack
resource "aws_elasticache_subnet_group" "redis" {
  name       = "founditure-${var.environment}-redis-subnet"
  subnet_ids = var.private_subnet_ids

  tags = {
    Environment = var.environment
    Project     = "Founditure"
    ManagedBy   = "Terraform"
  }
}

# Requirement: Performance
# Location: 2. SYSTEM ARCHITECTURE/2.2.1 Core Components
resource "aws_elasticache_parameter_group" "redis" {
  family = "redis6.x"
  name   = "founditure-${var.environment}-redis-params"
  description = "Custom parameters for Founditure Redis cluster"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "notify-keyspace-events"
    value = "Ex"
  }

  tags = {
    Environment = var.environment
    Project     = "Founditure"
    ManagedBy   = "Terraform"
  }
}

# Requirement: High Availability
# Location: 6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "founditure-${var.environment}-redis"
  description                   = "Founditure Redis cluster for ${var.environment}"
  node_type                     = var.redis_node_type
  num_cache_clusters           = var.multi_az ? 2 : 1
  port                         = 6379
  parameter_group_name         = aws_elasticache_parameter_group.redis.name
  subnet_group_name            = aws_elasticache_subnet_group.redis.name
  automatic_failover_enabled   = var.multi_az
  multi_az_enabled            = var.multi_az
  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = true
  auth_token_enabled         = true
  engine                     = "redis"
  engine_version             = "6.x"
  maintenance_window         = "sun:05:00-sun:06:00"
  snapshot_retention_limit   = 7
  snapshot_window            = "03:00-04:00"

  tags = {
    Environment = var.environment
    Project     = "Founditure"
    ManagedBy   = "Terraform"
  }
}

# Outputs for application configuration
output "redis_endpoint" {
  description = "Redis primary endpoint for application connection"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_port" {
  description = "Redis port number for application connection"
  value       = aws_elasticache_replication_group.redis.port
}

output "redis_connection_string" {
  description = "Complete Redis connection string with endpoint and port"
  value       = "${aws_elasticache_replication_group.redis.primary_endpoint_address}:${aws_elasticache_replication_group.redis.port}"
}