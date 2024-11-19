# Human Tasks:
# 1. Ensure AWS credentials are properly configured with necessary permissions for ECS resource creation
# 2. Verify VPC and subnet configurations are properly set up with required networking components
# 3. Review container definitions JSON structure before deployment
# 4. Confirm CloudWatch Container Insights IAM permissions if enabled
# 5. Validate security group rules for container communication

# Requirement: Container Orchestration
# Location: 6. INFRASTRUCTURE/6.4 ORCHESTRATION/Orchestration Specifications
variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod"
  }
}

# Requirement: Microservices Architecture
# Location: 2. SYSTEM ARCHITECTURE/2.2.1 Core Components
variable "service_name" {
  type        = string
  description = "Name of the ECS service"
  default     = "founditure"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.service_name))
    error_message = "Service name must contain only lowercase letters, numbers, and hyphens"
  }
}

# Requirement: High Availability
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
variable "vpc_id" {
  type        = string
  description = "ID of the VPC where ECS resources will be deployed"
  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC identifier"
  }
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for ECS tasks deployment across multiple AZs"
  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least two private subnets must be provided for high availability"
  }
}

# Requirement: Container Orchestration
# Location: 6. INFRASTRUCTURE/6.4 ORCHESTRATION/Orchestration Specifications
variable "container_definitions" {
  type        = string
  description = "JSON string of container definitions for ECS task including image, ports, environment variables, and resource limits"
  validation {
    condition     = can(jsondecode(var.container_definitions))
    error_message = "Container definitions must be a valid JSON string"
  }
}

# Requirement: High Availability
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
variable "desired_count" {
  type        = number
  description = "Desired number of ECS tasks to run for the service"
  default     = 3
  validation {
    condition     = var.desired_count >= 2
    error_message = "Desired count must be at least 2 for high availability"
  }
}

variable "min_capacity" {
  type        = number
  description = "Minimum number of tasks for auto-scaling group"
  default     = 2
  validation {
    condition     = var.min_capacity >= 2
    error_message = "Minimum capacity must be at least 2 for high availability"
  }
}

variable "max_capacity" {
  type        = number
  description = "Maximum number of tasks for auto-scaling group"
  default     = 10
  validation {
    condition     = var.max_capacity >= var.min_capacity
    error_message = "Maximum capacity must be greater than or equal to minimum capacity"
  }
}

# Requirement: Container Orchestration
# Location: 6. INFRASTRUCTURE/6.4 ORCHESTRATION/Orchestration Specifications
variable "cpu" {
  type        = number
  description = "CPU units for ECS task (1024 = 1 vCPU)"
  default     = 1024
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "CPU units must be one of [256, 512, 1024, 2048, 4096]"
  }
}

variable "memory" {
  type        = number
  description = "Memory (in MiB) for ECS task"
  default     = 2048
  validation {
    condition     = contains([512, 1024, 2048, 4096, 8192], var.memory)
    error_message = "Memory must be one of [512, 1024, 2048, 4096, 8192] MiB"
  }
}

# Requirement: Microservices Architecture
# Location: 2. SYSTEM ARCHITECTURE/2.2.1 Core Components
variable "container_port" {
  type        = number
  description = "Port exposed by the container for service communication"
  default     = 8080
  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "Container port must be between 1 and 65535"
  }
}

variable "health_check_grace_period" {
  type        = number
  description = "Grace period in seconds before starting health checks"
  default     = 60
  validation {
    condition     = var.health_check_grace_period >= 30 && var.health_check_grace_period <= 300
    error_message = "Health check grace period must be between 30 and 300 seconds"
  }
}

# Requirement: Container Orchestration
# Location: 6. INFRASTRUCTURE/6.4 ORCHESTRATION/Orchestration Specifications
variable "enable_container_insights" {
  type        = bool
  description = "Enable CloudWatch Container Insights for monitoring and observability"
  default     = true
}

# Requirement: Security Requirements
# Location: 5. SECURITY CONSIDERATIONS/5.1 Authentication and Authorization
variable "enable_execute_command" {
  type        = bool
  description = "Enable ECS Exec for debugging (should be disabled in production)"
  default     = false
}

# Requirement: High Availability
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
variable "deployment_maximum_percent" {
  type        = number
  description = "Maximum percentage of tasks that can run during deployment"
  default     = 200
  validation {
    condition     = var.deployment_maximum_percent >= 100 && var.deployment_maximum_percent <= 200
    error_message = "Deployment maximum percent must be between 100 and 200"
  }
}

variable "deployment_minimum_healthy_percent" {
  type        = number
  description = "Minimum percentage of tasks that must remain healthy during deployment"
  default     = 100
  validation {
    condition     = var.deployment_minimum_healthy_percent >= 0 && var.deployment_minimum_healthy_percent <= 100
    error_message = "Deployment minimum healthy percent must be between 0 and 100"
  }
}

# Requirement: Container Orchestration
# Location: 6. INFRASTRUCTURE/6.4 ORCHESTRATION/Orchestration Specifications
variable "tags" {
  type        = map(string)
  description = "Tags to apply to all ECS resources for resource management and cost allocation"
  default     = {}
}