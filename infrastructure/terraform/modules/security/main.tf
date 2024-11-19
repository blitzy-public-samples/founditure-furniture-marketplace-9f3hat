# AWS Provider version: ~> 4.0
# Random Provider version: ~> 3.0

# Human Tasks:
# 1. Review and adjust WAF rate limits based on application traffic patterns
# 2. Verify IAM roles and policies exist in AWS account before deployment
# 3. Ensure KMS key administrators are properly configured
# 4. Validate WAF rules against security requirements
# 5. Configure CloudWatch logging retention periods

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Local variables for resource configuration
locals {
  common_tags = {
    Project     = "Founditure"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # WAF rules configuration from JSON file
  waf_rules = jsondecode(file("${path.module}/../../../security/waf/rules.json"))

  # Security group rules with least privilege access
  security_group_rules = {
    ingress = [
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTPS inbound"
      }
    ]
    egress = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "All outbound traffic"
      }
    ]
  }

  # WAF visibility configuration
  waf_visibility_config = {
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled  = true
    metric_name              = "FounditureWAFMetrics-${var.environment}"
  }

  # Service roles from JSON configuration
  service_roles = jsondecode(file("${path.module}/../../../security/iam/roles/service-roles.json")).ServiceRoles
}

# Requirement: Data Security (5.2 DATA SECURITY)
# KMS key for data encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for Founditure application data encryption"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = var.enable_key_rotation
  
  tags = local.common_tags
}

resource "aws_kms_alias" "main" {
  name          = "alias/founditure-${var.environment}"
  target_key_id = aws_kms_key.main.key_id
}

# Requirement: Network Security (5.3.1 Network Security)
# WAF configuration with OWASP protections
resource "aws_wafv2_web_acl" "main" {
  name        = "founditure-${var.environment}-waf"
  description = "WAF rules for Founditure application"
  scope       = "REGIONAL"

  default_action {
    dynamic "allow" {
      for_each = local.waf_rules.default_action.allow != null ? [1] : []
      content {}
    }
    
    dynamic "block" {
      for_each = local.waf_rules.default_action.block != null ? [1] : []
      content {}
    }
  }

  # Managed rules from WAF configuration
  dynamic "rule" {
    for_each = local.waf_rules.managed_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "none" {
          for_each = rule.value.override_action.none != null ? [1] : []
          content {}
        }
        
        dynamic "count" {
          for_each = rule.value.override_action.count != null ? [1] : []
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.statement.managed_rule_group_statement.name
          vendor_name = rule.value.statement.managed_rule_group_statement.vendor_name
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled  = true
        metric_name              = "${rule.value.name}Metrics"
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = local.waf_visibility_config.cloudwatch_metrics_enabled
    sampled_requests_enabled  = local.waf_visibility_config.sampled_requests_enabled
    metric_name              = local.waf_visibility_config.metric_name
  }

  tags = local.common_tags
}

# Requirement: Network Security (5.3.1 Network Security)
# Security group with least privilege access
resource "aws_security_group" "main" {
  name        = "founditure-${var.environment}-sg"
  description = "Security group for Founditure application"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = local.security_group_rules.ingress
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = local.security_group_rules.egress
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }

  tags = local.common_tags
}

# Requirement: Authentication and Authorization (5.1 AUTHENTICATION AND AUTHORIZATION)
# Service IAM roles
resource "aws_iam_role" "service_roles" {
  for_each = local.service_roles

  name               = each.value.RoleName
  description        = each.value.Description
  assume_role_policy = jsonencode(each.value.AssumeRolePolicyDocument)
  path               = each.value.Path
  max_session_duration = each.value.MaxSessionDuration

  dynamic "inline_policy" {
    for_each = each.value.Policies
    content {
      name   = inline_policy.value.PolicyName
      policy = inline_policy.value.PolicyDocument
    }
  }

  tags = merge(local.common_tags, each.value.Tags)
}

# Output values for other modules
output "kms_key_id" {
  description = "ID of the created KMS key for data encryption"
  value       = aws_kms_key.main.key_id
}

output "waf_web_acl_id" {
  description = "ID of the created WAF web ACL"
  value       = aws_wafv2_web_acl.main.id
}

output "security_group_id" {
  description = "ID of the created security group"
  value       = aws_security_group.main.id
}

output "service_role_arns" {
  description = "ARNs of created service IAM roles"
  value = {
    for role_name, role in aws_iam_role.service_roles : role_name => role.arn
  }
}