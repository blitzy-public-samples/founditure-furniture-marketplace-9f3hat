# Human Tasks:
# 1. Ensure AWS credentials are properly configured with the founditure-dev profile
# 2. Verify that the S3 bucket 'founditure-terraform-dev-state' exists and is properly configured
# 3. Confirm that the DynamoDB table 'founditure-terraform-dev-locks' exists for state locking
# 4. Review CIDR block allocations to avoid conflicts with existing networks
# 5. Validate that container definitions are properly configured in the container module

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

  # Requirement: Infrastructure as Code
  # Location: 6. INFRASTRUCTURE/6.4 CI/CD PIPELINE
  backend "s3" {
    bucket         = "founditure-terraform-dev-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "founditure-terraform-dev-locks"
  }
}

# Requirement: Development Environment
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
provider "aws" {
  region  = local.region
  profile = "founditure-dev"

  default_tags {
    tags = {
      Environment = local.environment
      Project     = local.project
      ManagedBy   = "terraform"
    }
  }
}

# Local variables for environment-specific configuration
locals {
  environment        = "dev"
  project           = "founditure"
  region            = "us-east-1"
  vpc_cidr          = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
}

# Requirement: Cloud Infrastructure
# Location: 2. SYSTEM ARCHITECTURE/2.1 High-Level Architecture
module "networking" {
  source = "../../modules/networking"

  environment            = local.environment
  vpc_cidr              = local.vpc_cidr
  availability_zones    = local.availability_zones
  enable_dns_hostnames  = true
  enable_dns_support    = true
  single_nat_gateway    = true
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]

  tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "terraform"
  }
}

# Requirement: Container Orchestration
# Location: 6. INFRASTRUCTURE/6.4 ORCHESTRATION
module "container" {
  source = "../../modules/container"

  environment              = local.environment
  vpc_id                  = module.networking.vpc_id
  private_subnet_ids      = module.networking.private_subnet_ids
  service_name            = "founditure-api"
  cpu                     = 256
  memory                  = 512
  desired_count           = 1
  min_capacity            = 1
  max_capacity            = 2
  container_port          = 8080
  health_check_grace_period = 60
  enable_container_insights = true

  # Development environment specific container definition
  container_definitions = jsonencode([
    {
      name      = "founditure-api"
      image     = "founditure-api:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort     = 8080
          protocol     = "tcp"
        }
      ]
      environment = [
        {
          name  = "ENVIRONMENT"
          value = "dev"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/founditure-dev-api"
          "awslogs-region"        = local.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "terraform"
  }
}

# Requirement: Cloud Infrastructure
# Location: 2. SYSTEM ARCHITECTURE/2.1 High-Level Architecture
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.container.cluster_outputs.id
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.container.service_outputs.name
}