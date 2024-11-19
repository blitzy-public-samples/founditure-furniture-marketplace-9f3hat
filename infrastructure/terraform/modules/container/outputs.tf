# Requirement: Container Orchestration
# Location: 6. INFRASTRUCTURE/6.4 ORCHESTRATION
output "cluster" {
  description = "Comprehensive ECS cluster details including identifiers and configuration"
  value = {
    id   = aws_ecs_cluster.main.id
    name = aws_ecs_cluster.main.name
    arn  = aws_ecs_cluster.main.arn
  }
}

# Requirement: Microservices Architecture
# Location: 2. SYSTEM ARCHITECTURE/2.2.1 Core Components
output "service" {
  description = "Detailed ECS service configuration and runtime information"
  value = {
    id             = aws_ecs_service.main.id
    name           = aws_ecs_service.main.name
    cluster        = aws_ecs_service.main.cluster
    desired_count  = aws_ecs_service.main.desired_count
    launch_type    = aws_ecs_service.main.launch_type
    task_definition = aws_ecs_service.main.task_definition
  }
}

# Requirement: Container Orchestration
# Location: 6. INFRASTRUCTURE/6.4 ORCHESTRATION
output "task_definition" {
  description = "ECS task definition specifications and resource allocations"
  value = {
    arn      = aws_ecs_task_definition.main.arn
    family   = aws_ecs_task_definition.main.family
    revision = aws_ecs_task_definition.main.revision
    cpu      = aws_ecs_task_definition.main.cpu
    memory   = aws_ecs_task_definition.main.memory
  }
}

# Requirement: Microservices Architecture
# Location: 2. SYSTEM ARCHITECTURE/2.2.1 Core Components
output "security_group" {
  description = "Security group configuration for ECS tasks network access control"
  value = {
    id      = aws_security_group.ecs_tasks.id
    name    = aws_security_group.ecs_tasks.name
    vpc_id  = aws_security_group.ecs_tasks.vpc_id
  }
}