# AWS Provider version: ~> 4.0
# Required for AWS provider variable validation and security resource configuration

# Human Tasks:
# 1. Review and adjust WAF rate limits based on application traffic patterns
# 2. Verify IAM policies referenced in service_roles exist in AWS account
# 3. Ensure KMS key administrators are properly configured
# 4. Validate CIDR blocks against organization's network security policies

# Requirement: Network Security (5.3.1 Network Security)
# Environment variable for resource naming and security policy configuration
variable "environment" {
  description = "Environment name (dev, staging, prod) for deploying security configurations"
  type        = string

  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod"
  }
}

# Requirement: Network Security (5.3.1 Network Security)
# VPC ID for security group and WAF rule association
variable "vpc_id" {
  description = "ID of the VPC where security groups and WAF rules will be applied"
  type        = string

  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC identifier"
  }
}

# Requirement: Data Security (5.2 DATA SECURITY)
# KMS key deletion window configuration
variable "kms_key_deletion_window" {
  description = "Number of days before KMS key deletion (7-30 days)"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days"
  }
}

# Requirement: Network Security (5.3.1 Network Security)
# CIDR blocks for security group ingress rules
variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the application through security groups"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "All CIDR blocks must be valid IPv4 CIDR notation"
  }
}

# Requirement: Authentication and Authorization (5.1 AUTHENTICATION AND AUTHORIZATION)
# Service role configurations for IAM
variable "service_roles" {
  description = "Map of service names to their IAM role configurations including policies and session duration"
  type = map(object({
    name                 = string
    policies            = list(string)
    max_session_duration = number
  }))

  validation {
    condition     = alltrue([for k, v in var.service_roles : v.max_session_duration >= 3600 && v.max_session_duration <= 43200])
    error_message = "IAM role session duration must be between 1 and 12 hours (3600-43200 seconds)"
  }
}

# Requirement: Network Security (5.3.1 Network Security)
# WAF rate limiting configuration
variable "waf_rate_limit" {
  description = "Maximum number of requests per 5-minute period per IP for WAF rate limiting"
  type        = number
  default     = 2000

  validation {
    condition     = var.waf_rate_limit >= 100 && var.waf_rate_limit <= 20000
    error_message = "WAF rate limit must be between 100 and 20000 requests"
  }
}

# Requirement: Network Security (5.3.1 Network Security)
# WAF enablement flag
variable "enable_waf" {
  description = "Enable WAF protection and rules for the application"
  type        = bool
  default     = true
}

# Requirement: Data Security (5.2 DATA SECURITY)
# KMS key rotation configuration
variable "enable_key_rotation" {
  description = "Enable automatic KMS key rotation for enhanced security"
  type        = bool
  default     = true
}