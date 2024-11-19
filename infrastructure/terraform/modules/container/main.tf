# Human Tasks:
# 1. Ensure AWS credentials are properly configured with necessary ECS permissions
# 2. Review container definitions JSON for proper configuration
# 3. Validate security group CIDR blocks match network requirements
# 4. Verify CloudWatch Container Insights IAM roles are configured
# 5. Confirm auto-scaling thresholds align with application requirements

# AWS Provider version ~> 5.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Requirement: Container Orchestration
# Location: 6. INFRASTRUCTURE/6.4 ORCHESTRATION
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-${var.service_name}-cluster"

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight           = 1
    base            = 1
  }

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = var.tags
}

# Requirement: Microservices Architecture
# Location: 2. SYSTEM ARCHITECTURE/2.1 High-Level Architecture
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.environment}-${var.service_name}"
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = var.container_definitions
  execution_role_arn      = aws_iam_role.ecs_execution.arn
  task_role_arn           = aws_iam_role.ecs_task.arn

  tags = var.tags
}

# Requirement: High Availability
# Location: 6. INFRASTRUCTURE/6.4 ORCHESTRATION/Orchestration Specifications
resource "aws_ecs_service" "main" {
  name                              = "${var.environment}-${var.service_name}"
  cluster                          = aws_ecs_cluster.main.id
  task_definition                  = aws_ecs_task_definition.main.arn
  desired_count                    = var.desired_count
  launch_type                      = "FARGATE"
  platform_version                 = "LATEST"
  deployment_maximum_percent       = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds = var.health_check_grace_period
  enable_execute_command           = var.enable_execute_command

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = var.tags
}

# Requirement: High Availability
# Location: 6. INFRASTRUCTURE/6.4 ORCHESTRATION/Orchestration Specifications
resource "aws_appautoscaling_target" "ecs" {
  service_namespace  = "ecs"
  resource_id       = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity      = var.min_capacity
  max_capacity      = var.max_capacity
}

# Requirement: Security Controls
# Location: 5. SECURITY CONSIDERATIONS/5.3 SECURITY PROTOCOLS/Network Security
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.environment}-${var.service_name}-ecs-tasks"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow inbound container port"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-${var.service_name}-ecs-tasks"
    }
  )
}

# Requirement: Container Orchestration
# Location: 6. INFRASTRUCTURE/6.4 ORCHESTRATION
resource "aws_iam_role" "ecs_execution" {
  name = "${var.environment}-${var.service_name}-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name = "${var.environment}-${var.service_name}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Outputs for service integration
output "cluster_outputs" {
  value = {
    id   = aws_ecs_cluster.main.id
    name = aws_ecs_cluster.main.name
    arn  = aws_ecs_cluster.main.arn
  }
  description = "ECS cluster information"
}

output "service_outputs" {
  value = {
    id   = aws_ecs_service.main.id
    name = aws_ecs_service.main.name
    arn  = aws_ecs_service.main.arn
  }
  description = "ECS service information"
}