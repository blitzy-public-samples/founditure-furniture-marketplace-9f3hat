# AWS Provider version: ~> 5.0
# Required for AWS provider variable validation and VPC configuration

# Human Tasks:
# 1. Ensure AWS provider is configured with appropriate credentials and region
# 2. Verify that the specified availability zones exist in your target AWS region
# 3. Validate that CIDR blocks do not overlap with existing networks
# 4. Consider adjusting default values based on environment-specific requirements

# Requirement: Network Security (5.3.1)
# Configurable network isolation through VPC and subnet CIDR blocks with strict validation rules
variable "vpc_cidr" {
  description = "CIDR block for the VPC network infrastructure"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.vpc_cidr) != null
    error_message = "VPC CIDR block must be a valid IPv4 CIDR notation (e.g., 10.0.0.0/16)"
  }
}

# Requirement: Cloud Infrastructure (6.2)
# Network configuration variables for AWS services including ECS Fargate, RDS, ElastiCache, and S3
variable "environment" {
  description = "Environment identifier used for resource naming and tagging (dev/staging/prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

# Requirement: High Availability (6.1)
# Multi-AZ deployment configuration through availability zone variables with minimum redundancy requirements
variable "availability_zones" {
  description = "List of AWS availability zones for multi-AZ deployment. Minimum 2 AZs required for high availability"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones must be specified for high availability"
  }
}

# Requirement: Network Security (5.3.1)
# Public subnet configuration for external-facing resources
variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets, one per AZ. Used for load balancers and NAT gateways"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.availability_zones) && alltrue([for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Number of public subnet CIDRs must match number of availability zones and each CIDR must be valid"
  }
}

# Requirement: Network Security (5.3.1)
# Private subnet configuration for internal resources
variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets, one per AZ. Used for ECS tasks, RDS, and ElastiCache"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.availability_zones) && alltrue([for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Number of private subnet CIDRs must match number of availability zones and each CIDR must be valid"
  }
}

# Requirement: Cloud Infrastructure (6.2)
# DNS configuration for service discovery
variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC for service discovery"
  type        = bool
  default     = true
}

# Requirement: Cloud Infrastructure (6.2)
# DNS support for internal name resolution
variable "enable_dns_support" {
  description = "Enable DNS support in the VPC for name resolution"
  type        = bool
  default     = true
}

# Requirement: High Availability (6.1)
# NAT Gateway configuration for high availability
variable "single_nat_gateway" {
  description = "Use a single NAT Gateway instead of one per AZ. Set to false for production high availability"
  type        = bool
  default     = false
}

# Requirement: Cloud Infrastructure (6.2)
# Resource tagging for management and organization
variable "tags" {
  description = "Additional tags to apply to all networking resources for resource management"
  type        = map(string)
  default     = {}
}