# Human Tasks:
# 1. Review and validate instance types for monitoring components based on workload requirements
# 2. Ensure Grafana admin password meets security requirements and is stored securely
# 3. Verify retention periods align with data retention policies and compliance requirements
# 4. Review network security group rules for monitoring components
# 5. Validate EBS volume sizes based on expected monitoring data volume

# Provider configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # version ~> 5.0
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes" # version ~> 2.0
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm" # version ~> 2.0
      version = "~> 2.0"
    }
  }
}

# Local variables
locals {
  name_prefix = "${var.environment}-monitoring"
  common_tags = {
    Environment = var.environment
    Project     = "founditure"
    ManagedBy   = "terraform"
  }
}

# Data sources
data "aws_vpc" "selected_vpc" {
  id = var.vpc_id
}

data "aws_subnets" "selected_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# Requirement: System Monitoring
# Location: 2. SYSTEM ARCHITECTURE/2.4 Cross-Cutting Concerns/2.4.1 System Monitoring
resource "aws_security_group" "monitoring" {
  name_prefix = "${local.name_prefix}-sg"
  vpc_id      = var.vpc_id
  description = "Security group for monitoring infrastructure"

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected_vpc.cidr_block]
    description = "Prometheus"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected_vpc.cidr_block]
    description = "Grafana"
  }

  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected_vpc.cidr_block]
    description = "Elasticsearch"
  }

  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected_vpc.cidr_block]
    description = "Kibana"
  }

  ingress {
    from_port   = 14250
    to_port     = 14250
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected_vpc.cidr_block]
    description = "Jaeger"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sg"
  })
}

# Requirement: Performance Metrics
# Location: 4. TECHNOLOGY STACK/4.4 THIRD-PARTY SERVICES
resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${local.name_prefix}-prometheus"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 1024
  memory                  = 2048
  execution_role_arn      = aws_iam_role.monitoring_execution.arn
  task_role_arn           = aws_iam_role.monitoring_task.arn

  container_definitions = jsonencode([
    {
      name  = "prometheus"
      image = "prom/prometheus:v2.45.0"
      portMappings = [
        {
          containerPort = 9090
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "PROMETHEUS_RETENTION_PERIOD"
          value = var.prometheus_retention_period
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "prometheus-data"
          containerPath = "/prometheus"
          readOnly     = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.monitoring.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "prometheus"
        }
      }
    }
  ])

  volume {
    name = "prometheus-data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.prometheus.id
      root_directory = "/"
    }
  }

  tags = local.common_tags
}

# Requirement: Performance Metrics
# Location: 4. TECHNOLOGY STACK/4.4 THIRD-PARTY SERVICES
resource "aws_ecs_service" "prometheus" {
  name            = "${local.name_prefix}-prometheus"
  cluster         = aws_ecs_cluster.monitoring.id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.monitoring.id]
    assign_public_ip = false
  }

  tags = local.common_tags
}

# Requirement: Observability
# Location: 2. SYSTEM ARCHITECTURE/2.4 Cross-Cutting Concerns
resource "helm_release" "grafana" {
  name       = "${local.name_prefix}-grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "6.50.7"
  namespace  = "monitoring"

  set {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = "10Gi"
  }

  values = [
    yamlencode({
      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = [
            {
              name      = "Prometheus"
              type      = "prometheus"
              url       = "http://${aws_service_discovery_service.prometheus.name}:9090"
              isDefault = true
            }
          ]
        }
      }
    })
  ]
}

# Requirement: Observability
# Location: 2. SYSTEM ARCHITECTURE/2.4 Cross-Cutting Concerns
resource "helm_release" "elastic" {
  name       = "${local.name_prefix}-elastic"
  repository = "https://helm.elastic.co"
  chart      = "elasticsearch"
  version    = "7.17.3"
  namespace  = "monitoring"

  set {
    name  = "cluster.name"
    value = "${local.name_prefix}-es"
  }

  set {
    name  = "retention.days"
    value = var.elk_retention_days
  }
}

# Requirement: System Monitoring
# Location: 2. SYSTEM ARCHITECTURE/2.4 Cross-Cutting Concerns/2.4.1 System Monitoring
resource "helm_release" "jaeger" {
  name       = "${local.name_prefix}-jaeger"
  repository = "https://jaegertracing.github.io/helm-charts"
  chart      = "jaeger"
  version    = "0.71.3"
  namespace  = "monitoring"

  set {
    name  = "storage.type"
    value = "elasticsearch"
  }

  set {
    name  = "storage.elasticsearch.host"
    value = "${local.name_prefix}-elastic-elasticsearch-client"
  }
}

# Supporting resources
resource "aws_ecs_cluster" "monitoring" {
  name = "${local.name_prefix}-cluster"
  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "monitoring" {
  name              = "/aws/ecs/${local.name_prefix}"
  retention_in_days = 30
  tags             = local.common_tags
}

resource "aws_efs_file_system" "prometheus" {
  creation_token = "${local.name_prefix}-prometheus-data"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = local.common_tags
}

# IAM roles and policies
resource "aws_iam_role" "monitoring_execution" {
  name = "${local.name_prefix}-execution-role"

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

  tags = local.common_tags
}

resource "aws_iam_role" "monitoring_task" {
  name = "${local.name_prefix}-task-role"

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

  tags = local.common_tags
}

# Outputs
output "monitoring_resources" {
  value = {
    prometheus_endpoint   = "http://${aws_service_discovery_service.prometheus.name}:9090"
    grafana_endpoint     = "http://${helm_release.grafana.name}:3000"
    kibana_endpoint      = "http://${helm_release.elastic.name}-kibana:5601"
    jaeger_endpoint      = "http://${helm_release.jaeger.name}-query:16686"
    elasticsearch_endpoint = "http://${helm_release.elastic.name}-elasticsearch-client:9200"
  }
  description = "Monitoring infrastructure endpoints"
}

data "aws_region" "current" {}