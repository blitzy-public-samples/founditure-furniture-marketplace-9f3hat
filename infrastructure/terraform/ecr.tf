# AWS Provider version ~> 5.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Requirement: Container Registry
# Location: 6.2 CLOUD SERVICES/AWS Service Stack
# Creates ECR repository for API Gateway service
resource "aws_ecr_repository" "api_gateway" {
  name                 = "founditure-api-gateway-${var.environment}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = var.tags
}

# Requirement: Container Registry
# Location: 6.2 CLOUD SERVICES/AWS Service Stack
# Creates ECR repository for Auth service
resource "aws_ecr_repository" "auth_service" {
  name                 = "founditure-auth-service-${var.environment}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = var.tags
}

# Requirement: Container Registry
# Location: 6.2 CLOUD SERVICES/AWS Service Stack
# Creates ECR repository for Listing service
resource "aws_ecr_repository" "listing_service" {
  name                 = "founditure-listing-service-${var.environment}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = var.tags
}

# Requirement: Container Registry
# Location: 6.2 CLOUD SERVICES/AWS Service Stack
# Creates ECR repository for Messaging service
resource "aws_ecr_repository" "messaging_service" {
  name                 = "founditure-messaging-service-${var.environment}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = var.tags
}

# Requirement: Container Registry
# Location: 6.2 CLOUD SERVICES/AWS Service Stack
# Creates ECR repository for AI service
resource "aws_ecr_repository" "ai_service" {
  name                 = "founditure-ai-service-${var.environment}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = var.tags
}

# Requirement: CI/CD Pipeline
# Location: 6.5 CI/CD PIPELINE/Pipeline Stages
# Lifecycle policy for API Gateway repository
resource "aws_ecr_lifecycle_policy" "api_gateway" {
  repository = aws_ecr_repository.api_gateway.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod"]
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 10 staging images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["staging"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Remove untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Apply the same lifecycle policy to Auth service repository
resource "aws_ecr_lifecycle_policy" "auth_service" {
  repository = aws_ecr_repository.auth_service.name
  policy     = aws_ecr_lifecycle_policy.api_gateway.policy
}

# Apply the same lifecycle policy to Listing service repository
resource "aws_ecr_lifecycle_policy" "listing_service" {
  repository = aws_ecr_repository.listing_service.name
  policy     = aws_ecr_lifecycle_policy.api_gateway.policy
}

# Apply the same lifecycle policy to Messaging service repository
resource "aws_ecr_lifecycle_policy" "messaging_service" {
  repository = aws_ecr_repository.messaging_service.name
  policy     = aws_ecr_lifecycle_policy.api_gateway.policy
}

# Apply the same lifecycle policy to AI service repository
resource "aws_ecr_lifecycle_policy" "ai_service" {
  repository = aws_ecr_repository.ai_service.name
  policy     = aws_ecr_lifecycle_policy.api_gateway.policy
}

# Requirement: Security Controls
# Location: 5.3 SECURITY PROTOCOLS/Security Controls
# Output repository URLs for use in deployment configurations
output "repository_urls" {
  description = "Map of service names to their ECR repository URLs for use in deployment configurations"
  value = {
    api_gateway       = aws_ecr_repository.api_gateway.repository_url
    auth_service      = aws_ecr_repository.auth_service.repository_url
    listing_service   = aws_ecr_repository.listing_service.repository_url
    messaging_service = aws_ecr_repository.messaging_service.repository_url
    ai_service        = aws_ecr_repository.ai_service.repository_url
  }
}

# Output repository ARNs for IAM policy attachments
output "repository_arns" {
  description = "Map of service names to their ECR repository ARNs for IAM policy attachments"
  value = {
    api_gateway       = aws_ecr_repository.api_gateway.arn
    auth_service      = aws_ecr_repository.auth_service.arn
    listing_service   = aws_ecr_repository.listing_service.arn
    messaging_service = aws_ecr_repository.messaging_service.arn
    ai_service        = aws_ecr_repository.ai_service.arn
  }
}