# Human Tasks:
# 1. Review container definitions JSON for each microservice
# 2. Validate IAM roles and policies for ECS tasks
# 3. Verify load balancer target group configurations
# 4. Confirm security group rules for ECS tasks
# 5. Review auto-scaling thresholds based on expected workload

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
# Location: 6.2 CLOUD SERVICES/AWS Service Stack
resource "aws_ecs_cluster" "main" {
  name = "founditure-${var.environment}"

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight           = 1
    base             = 1
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Environment = var.environment
    Project     = "Founditure"
    ManagedBy   = "Terraform"
  }
}

# IAM roles for ECS tasks
resource "aws_iam_role" "ecs_execution_role" {
  name = "founditure-${var.environment}-ecs-execution"

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
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "founditure-${var.environment}-ecs-task"

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
}

# Security group for ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "founditure-${var.environment}-ecs-tasks"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Requirement: High Availability
# Location: 6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
locals {
  microservices = [
    "api-gateway",
    "auth-service",
    "listing-service",
    "messaging-service",
    "ai-service",
    "gamification-service",
    "notification-service",
    "analytics-service"
  ]
}

# Task definitions for each microservice
resource "aws_ecs_task_definition" "services" {
  for_each = toset(local.microservices)

  family                   = each.value
  cpu                      = "1024"
  memory                   = "2048"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = each.value
      image = "founditure/${each.value}:latest"
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/founditure/${var.environment}/${each.value}"
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        }
      ]
    }
  ])

  tags = {
    Environment = var.environment
    Service     = each.value
    ManagedBy   = "Terraform"
  }
}

# Requirement: Service Scaling
# Location: 6.4 ORCHESTRATION/Orchestration Specifications
resource "aws_ecs_service" "services" {
  for_each = toset(local.microservices)

  name                               = each.value
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition[each.value].arn
  desired_count                     = 3
  launch_type                       = "FARGATE"
  platform_version                  = "LATEST"
  deployment_maximum_percent        = 200
  deployment_minimum_healthy_percent = 100
  health_check_grace_period_seconds = 60
  propagate_tags                    = "SERVICE"
  enable_execute_command            = false

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group[each.value].arn
    container_name   = each.value
    container_port   = 80
  }

  tags = {
    Environment = var.environment
    Service     = each.value
    ManagedBy   = "Terraform"
  }
}

# Auto-scaling configuration
resource "aws_appautoscaling_target" "ecs_target" {
  for_each = toset(local.microservices)

  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.services[each.value].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  for_each = toset(local.microservices)

  name               = "${each.value}-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.value].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.value].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.value].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Outputs
output "ecs_cluster_id" {
  description = "The ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_names" {
  description = "The names of the ECS services"
  value       = [for service in aws_ecs_service.services : service.name]
}