# Human Tasks:
# 1. Review and validate instance types for monitoring components based on workload requirements
# 2. Ensure Grafana admin password meets organizational security requirements
# 3. Verify retention periods align with compliance and data storage requirements
# 4. Confirm subnet IDs are correctly specified for high availability
# 5. Review CloudWatch log group configurations for proper integration

# Requirement: System Monitoring
# Location: 2. SYSTEM ARCHITECTURE/2.4 Cross-Cutting Concerns/2.4.1 System Monitoring
variable "environment" {
  type        = string
  description = "Environment name (dev/staging/prod)"
  
  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Requirement: System Monitoring
# Location: 2. SYSTEM ARCHITECTURE/2.4 Cross-Cutting Concerns/2.4.1 System Monitoring
variable "vpc_id" {
  type        = string
  description = "ID of the VPC where monitoring infrastructure will be deployed"
}

# Requirement: System Monitoring
# Location: 2. SYSTEM ARCHITECTURE/2.4 Cross-Cutting Concerns/2.4.1 System Monitoring
variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for monitoring components deployment"
}

# Requirement: Performance Metrics
# Location: 4. TECHNOLOGY STACK/4.4 THIRD-PARTY SERVICES
variable "prometheus_retention_period" {
  type        = string
  description = "Data retention period for Prometheus (e.g., 15d)"
  default     = "15d"
  
  validation {
    condition     = can(regex("^[0-9]+d$", var.prometheus_retention_period))
    error_message = "Prometheus retention period must be specified in days with format: <number>d"
  }
}

# Requirement: Performance Metrics
# Location: 4. TECHNOLOGY STACK/4.4 THIRD-PARTY SERVICES
variable "grafana_admin_password" {
  type        = string
  description = "Admin password for Grafana"
  sensitive   = true
}

# Requirement: Observability
# Location: 2. SYSTEM ARCHITECTURE/2.4 Cross-Cutting Concerns
variable "elk_retention_days" {
  type        = number
  description = "Number of days to retain logs in ELK Stack"
  default     = 30
  
  validation {
    condition     = var.elk_retention_days >= 1 && var.elk_retention_days <= 90
    error_message = "ELK retention days must be between 1 and 90"
  }
}

# Requirement: Performance Metrics
# Location: 4. TECHNOLOGY STACK/4.4 THIRD-PARTY SERVICES
variable "prometheus_instance_type" {
  type        = string
  description = "EC2 instance type for Prometheus server"
  default     = "t3.medium"
}

# Requirement: Performance Metrics
# Location: 4. TECHNOLOGY STACK/4.4 THIRD-PARTY SERVICES
variable "prometheus_storage_size" {
  type        = number
  description = "Storage size in GB for Prometheus server"
  default     = 100
  
  validation {
    condition     = var.prometheus_storage_size >= 50 && var.prometheus_storage_size <= 1000
    error_message = "Prometheus storage size must be between 50 and 1000 GB"
  }
}

# Requirement: Performance Metrics
# Location: 4. TECHNOLOGY STACK/4.4 THIRD-PARTY SERVICES
variable "grafana_instance_type" {
  type        = string
  description = "EC2 instance type for Grafana server"
  default     = "t3.small"
}

# Requirement: Observability
# Location: 2. SYSTEM ARCHITECTURE/2.4 Cross-Cutting Concerns
variable "elasticsearch_instance_type" {
  type        = string
  description = "EC2 instance type for Elasticsearch nodes"
  default     = "t3.medium"
}

# Requirement: Observability
# Location: 2. SYSTEM ARCHITECTURE/2.4 Cross-Cutting Concerns
variable "jaeger_storage_type" {
  type        = string
  description = "Storage backend type for Jaeger (elasticsearch/cassandra)"
  default     = "elasticsearch"
  
  validation {
    condition     = contains(["elasticsearch", "cassandra"], var.jaeger_storage_type)
    error_message = "Jaeger storage type must be either elasticsearch or cassandra"
  }
}

# Requirement: Observability
# Location: 2. SYSTEM ARCHITECTURE/2.4 Cross-Cutting Concerns
variable "jaeger_retention_days" {
  type        = number
  description = "Number of days to retain traces in Jaeger"
  default     = 7
  
  validation {
    condition     = var.jaeger_retention_days >= 1 && var.jaeger_retention_days <= 30
    error_message = "Jaeger retention days must be between 1 and 30"
  }
}