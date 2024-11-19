# Provider version constraints
# AWS Provider version ~> 5.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source to get current AWS account information for KMS policy
data "aws_caller_identity" "current" {}

# Local variables for KMS configuration
locals {
  # Requirement: Data Encryption
  # Location: 5. SECURITY CONSIDERATIONS/5.2 DATA SECURITY/Encryption Standards
  kms_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow service-linked role use of the key"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.founditure_service_role.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# Requirement: Key Management
# Location: 5. SECURITY CONSIDERATIONS/5.2 DATA SECURITY/Data Protection Flow
resource "aws_kms_key" "founditure_master_key" {
  description              = "Master key for Founditure ${var.environment} environment"
  deletion_window_in_days  = 30
  enable_key_rotation      = true
  is_enabled              = true
  policy                  = local.kms_policy
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  key_usage               = "ENCRYPT_DECRYPT"
  multi_region            = false

  tags = merge(var.tags, {
    Name = "founditure-master-key-${var.environment}"
  })
}

# Requirement: Security Compliance
# Location: 5. SECURITY CONSIDERATIONS/5.3.3 Security Compliance
resource "aws_kms_alias" "founditure_key_alias" {
  name          = "alias/founditure-${var.environment}"
  target_key_id = aws_kms_key.founditure_master_key.key_id
}

# Output the KMS key ID and ARN for use by other services
output "founditure_kms_key_id" {
  description = "ID of the Founditure master KMS key"
  value       = aws_kms_key.founditure_master_key.key_id
}

output "founditure_kms_key_arn" {
  description = "ARN of the Founditure master KMS key"
  value       = aws_kms_key.founditure_master_key.arn
}