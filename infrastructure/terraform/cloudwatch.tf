# Provider configuration
# AWS Provider Version: ~> 5.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Requirement: System Monitoring
# Location: 2. SYSTEM ARCHITECTURE/2.4 Cross-Cutting Concerns/2.4.1 System Monitoring
# KMS key for CloudWatch log encryption
resource "aws_kms_key" "cloudwatch" {
  description             = "KMS key for CloudWatch log encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "kms:*"
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Requirement: Security Monitoring
# Location: 5. SECURITY CONSIDERATIONS/5.3 SECURITY PROTOCOLS/5.3.4 Security Monitoring
# KMS key for SNS topic encryption
resource "aws_kms_key" "sns" {
  description             = "KMS key for SNS topic encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "kms:*"
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "Allow SNS Service"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Requirement: Performance Monitoring
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/api-gateway/${var.environment}"
  retention_in_days = 30
  kms_key_id       = aws_kms_key.cloudwatch.arn
  tags             = var.tags
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/aws/ecs/${var.environment}"
  retention_in_days = 30
  kms_key_id       = aws_kms_key.cloudwatch.arn
  tags             = var.tags
}

resource "aws_cloudwatch_log_group" "rds" {
  name              = "/aws/rds/${var.environment}"
  retention_in_days = 30
  kms_key_id       = aws_kms_key.cloudwatch.arn
  tags             = var.tags
}

resource "aws_cloudwatch_log_group" "security" {
  name              = "/aws/security/${var.environment}"
  retention_in_days = 90
  kms_key_id       = aws_kms_key.cloudwatch.arn
  tags             = var.tags
}

# Requirement: System Monitoring
# Location: 2. SYSTEM ARCHITECTURE/2.4 Cross-Cutting Concerns/2.4.1 System Monitoring
# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name              = "${var.environment}-founditure-alerts"
  kms_master_key_id = aws_kms_key.sns.arn
  tags             = var.tags
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${var.environment}-api-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "Latency"
  namespace          = "AWS/ApiGateway"
  period             = 300
  statistic          = "Average"
  threshold          = 1000
  alarm_description  = "API Gateway latency is too high"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  tags               = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "${var.environment}-ecs-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "CPUUtilization"
  namespace          = "AWS/ECS"
  period             = 300
  statistic          = "Average"
  threshold          = 80
  alarm_description  = "ECS CPU utilization is too high"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  tags               = var.tags
}

resource "aws_cloudwatch_metric_alarm" "security_events" {
  alarm_name          = "${var.environment}-security-events"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name        = "UnauthorizedAPIRequests"
  namespace          = "AWS/ApiGateway"
  period             = 300
  statistic          = "Sum"
  threshold          = 10
  alarm_description  = "High number of unauthorized API requests detected"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  tags               = var.tags
}

# Requirement: Performance Monitoring
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-founditure-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Latency"],
            ["AWS/ECS", "CPUUtilization"],
            ["AWS/RDS", "DatabaseConnections"],
            ["AWS/ApiGateway", "UnauthorizedAPIRequests"]
          ]
          period = 300
          region = var.region
          title  = "Service Metrics Overview"
        }
      }
    ]
  })
  tags = var.tags
}

# Data source for AWS account ID
data "aws_caller_identity" "current" {}

# Outputs for other modules
output "cloudwatch_log_groups" {
  value = {
    api_gateway_log_group = aws_cloudwatch_log_group.api_gateway.name
    ecs_log_group        = aws_cloudwatch_log_group.ecs.name
    rds_log_group        = aws_cloudwatch_log_group.rds.name
    security_log_group   = aws_cloudwatch_log_group.security.name
  }
  description = "CloudWatch Log Group references for service configuration"
}

output "alert_topic" {
  value       = aws_sns_topic.alerts.arn
  description = "SNS topic ARN for alarm configuration"
}

output "kms_keys" {
  value = {
    cloudwatch_key_arn = aws_kms_key.cloudwatch.arn
    sns_key_arn       = aws_kms_key.sns.arn
  }
  description = "KMS key ARNs for encryption configuration"
}