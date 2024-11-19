# Human Tasks:
# 1. Ensure AWS credentials are properly configured in ~/.aws/credentials or via environment variables
# 2. Verify AWS account has access to required services: ECS, RDS, ElastiCache, S3, CloudFront, Route53
# 3. Confirm IAM permissions are properly set for Terraform operations
# 4. Review default tags and adjust if needed for your organization's tagging strategy

# Requirement: Multi-Region Deployment
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    # AWS Provider v5.0.x
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    
    # Random Provider v3.5.x
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    
    # Null Provider v3.2.x
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# Requirement: AWS Service Integration
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
# Requirement: Security Configuration
# Location: 5. SECURITY CONSIDERATIONS/5.3 SECURITY PROTOCOLS/Security Compliance
provider "aws" {
  region = var.region

  # Enable default encryption for all applicable services
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "Founditure"
      ManagedBy   = "Terraform"
    }
  }

  # Security best practices
  default_network_acl_deny_all = true
  default_security_group_deny_all = true
  
  # Enforce SSL/TLS for API calls
  endpoints {
    s3 = "https://s3.${var.region}.amazonaws.com"
  }
}