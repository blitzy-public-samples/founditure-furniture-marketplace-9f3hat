# Human Tasks:
# 1. Review and validate IAM role names align with organization naming conventions
# 2. Confirm the S3 bucket naming pattern matches your organization's standards
# 3. Verify that the Rekognition actions align with application requirements
# 4. Ensure the AWS account has permissions to create and manage IAM roles

# AWS Provider version specification
# Provider: hashicorp/aws ~> 5.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Import required variables from variables.tf
variable "environment" {}
variable "region" {}

# Define common tags as locals for resource tagging
locals {
  common_tags = {
    Project     = "Founditure"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Requirement: Authentication and Authorization
# Location: 5. SECURITY CONSIDERATIONS/5.1 AUTHENTICATION AND AUTHORIZATION
# ECS Task Execution Role - Allows ECS to pull container images and write logs
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "founditure-ecs-task-execution-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# Requirement: Cloud Services Security
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES
# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Requirement: Security Compliance
# Location: 5. SECURITY CONSIDERATIONS/5.3.3 Security Compliance
# ECS Task Role - Provides permissions for containers to access AWS services
resource "aws_iam_role" "ecs_task_role" {
  name = "founditure-ecs-task-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# Requirement: Cloud Services Security
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES
# S3 access policy for ECS tasks with least privilege principle
resource "aws_iam_role_policy" "ecs_task_s3_policy" {
  name = "founditure-s3-access-${var.environment}"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::founditure-${var.environment}/*",
          "arn:aws:s3:::founditure-${var.environment}"
        ]
      }
    ]
  })
}

# Requirement: Cloud Services Security
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES
# Rekognition access policy for furniture image analysis
resource "aws_iam_role_policy" "ecs_task_rekognition_policy" {
  name = "founditure-rekognition-access-${var.environment}"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rekognition:DetectLabels",
          "rekognition:DetectModerationLabels"
        ]
        Resource = "*"
      }
    ]
  })
}

# Output the role ARNs for use in other Terraform configurations
output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role for use in ECS task definitions"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role for use in ECS task definitions"
  value       = aws_iam_role.ecs_task_role.arn
}