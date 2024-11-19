# Human Tasks:
# 1. Ensure AWS credentials are properly configured for staging environment
# 2. Verify S3 bucket and DynamoDB table exist for Terraform state management
# 3. Review CIDR blocks to avoid overlap with other environments
# 4. Validate container service configurations match application requirements
# 5. Confirm CloudWatch Container Insights IAM roles are properly configured

# Requirement: Infrastructure as Code
# Location: 6. INFRASTRUCTURE/6.4 CI/CD PIPELINE/Pipeline Stages
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # version: ~> 5.0
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random" # version: ~> 3.0
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "founditure-terraform-state"
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "founditure-terraform-locks"
  }
}

# Requirement: Staging Environment Configuration
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "Founditure"
      ManagedBy   = "Terraform"
    }
  }
}

# Requirement: Network Security
# Location: 5. SECURITY CONSIDERATIONS/5.3.1 Network Security
module "networking" {
  source = "../../modules/networking"

  environment            = var.environment
  vpc_cidr              = "10.1.0.0/16"
  availability_zones    = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs   = ["10.1.0.0/24", "10.1.1.0/24"]
  private_subnet_cidrs  = ["10.1.2.0/24", "10.1.3.0/24"]
  enable_dns_hostnames  = true
  enable_dns_support    = true
  enable_nat_gateway    = true
  single_nat_gateway    = true # Cost optimization for staging
  
  tags = {
    Environment = var.environment
    Project     = "Founditure"
  }
}

# Requirement: Container Orchestration
# Location: 6. INFRASTRUCTURE/6.4 ORCHESTRATION/Orchestration Specifications
module "container" {
  source = "../../modules/container"

  environment              = var.environment
  vpc_id                  = module.networking.vpc_id
  private_subnet_ids      = module.networking.private_subnet_ids
  cluster_name            = "founditure-staging"
  enable_container_insights = true

  services = {
    api_gateway = {
      cpu                = 1024
      memory             = 2048
      desired_count      = 2
      min_capacity       = 2
      max_capacity       = 4
      container_port     = 8080
      health_check_grace_period = 60
    }
    auth_service = {
      cpu                = 512
      memory             = 1024
      desired_count      = 2
      min_capacity       = 2
      max_capacity       = 4
      container_port     = 8081
      health_check_grace_period = 60
    }
    listing_service = {
      cpu                = 512
      memory             = 1024
      desired_count      = 2
      min_capacity       = 2
      max_capacity       = 4
      container_port     = 8082
      health_check_grace_period = 60
    }
  }
}

# Requirement: Infrastructure as Code
# Location: 6. INFRASTRUCTURE/6.4 CI/CD PIPELINE/Pipeline Stages
output "vpc_id" {
  description = "ID of the staging VPC"
  value       = module.networking.vpc_id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.container.cluster_outputs.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.container.cluster_outputs.arn
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}