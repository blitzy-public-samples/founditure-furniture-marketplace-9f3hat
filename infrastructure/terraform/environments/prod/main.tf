# Human Tasks:
# 1. Verify AWS credentials are properly configured for production account
# 2. Ensure S3 bucket for Terraform state exists and is properly secured
# 3. Confirm DynamoDB table for state locking is created
# 4. Review and validate production environment variables
# 5. Verify multi-AZ availability zones are enabled in target region

# AWS Provider version: ~> 5.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Requirement: Production Environment Configuration
  # Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
  backend "s3" {
    bucket         = "founditure-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "founditure-terraform-locks"
  }
}

# Requirement: Production Environment Configuration
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = "prod"
      Project     = "Founditure"
      ManagedBy   = "Terraform"
    }
  }
}

# Requirement: High Availability
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
locals {
  environment_config = {
    prod = {
      multi_az             = true
      instance_count       = 3
      db_instance_class    = "db.r6g.xlarge"
      ecs_instance_type    = "t3.large"
      redis_node_type      = "cache.r6g.large"
      backup_retention_days = 30
    }
  }
}

# Requirement: High Availability
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
module "networking" {
  source = "../../modules/networking"

  environment         = "prod"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = var.availability_zones
  enable_nat_gateway = true
  nat_gateway_count  = 3
  enable_vpn_gateway = true

  tags = {
    Environment = "prod"
    Project     = "Founditure"
    ManagedBy   = "Terraform"
  }
}

# Requirement: Security Controls
# Location: 5. SECURITY CONSIDERATIONS/5.3.1 Network Security
module "container" {
  source = "../../modules/container"

  environment          = "prod"
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  cluster_name        = "founditure-prod"
  desired_count       = 3
  max_capacity        = 10
  min_capacity        = 3
  cpu_threshold       = 70
  memory_threshold    = 80
  
  # Enable production monitoring features
  enable_container_insights = true
  enable_execute_command   = true

  tags = {
    Environment = "prod"
    Project     = "Founditure"
    ManagedBy   = "Terraform"
  }
}

# Requirement: Production Environment Configuration
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
output "vpc_id" {
  description = "ID of the production VPC"
  value       = module.networking.vpc_id
}

output "ecs_cluster_id" {
  description = "ID of the production ECS cluster"
  value       = module.container.cluster_id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.networking.private_subnet_ids
}