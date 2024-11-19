# Requirement: Cloud Infrastructure (6.2 CLOUD SERVICES/AWS Service Stack)
# VPC ID output for use by other AWS services and modules
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

# Requirement: Network Security (5.3.1 Network Security)
# VPC CIDR output for security group and network planning
output "vpc_cidr" {
  description = "CIDR block of the created VPC"
  value       = aws_vpc.main.cidr_block
}

# Requirement: High Availability (6.1 DEPLOYMENT ENVIRONMENT)
# Public subnet IDs for ALB and other public-facing resources
output "public_subnet_ids" {
  description = "List of public subnet IDs created in the VPC"
  value       = aws_subnet.public[*].id
}

# Requirement: High Availability (6.1 DEPLOYMENT ENVIRONMENT)
# Private subnet IDs for ECS services and database deployments
output "private_subnet_ids" {
  description = "List of private subnet IDs created in the VPC"
  value       = aws_subnet.private[*].id
}

# Requirement: Network Security (5.3.1 Network Security)
# Security group ID for the application load balancer
output "alb_security_group_id" {
  description = "ID of the security group created for the application load balancer"
  value       = aws_security_group.alb.id
}

# Requirement: Network Security (5.3.1 Network Security)
# Security group ID for ECS services
output "ecs_security_group_id" {
  description = "ID of the security group created for ECS services"
  value       = aws_security_group.ecs.id
}

# Requirement: High Availability (6.1 DEPLOYMENT ENVIRONMENT)
# NAT Gateway Elastic IP addresses for network planning
output "nat_gateway_ips" {
  description = "List of Elastic IP addresses associated with NAT gateways"
  value       = aws_eip.nat[*].public_ip
}