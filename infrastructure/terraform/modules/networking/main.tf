# AWS Provider version: ~> 5.0
# Terraform AWS provider for infrastructure resource management

# Human Tasks:
# 1. Ensure AWS credentials are properly configured
# 2. Verify that the specified CIDR blocks don't overlap with existing VPCs
# 3. Confirm availability zones are available in target region
# 4. Review security group rules for production readiness
# 5. Consider enabling VPC flow logs for network monitoring

# Requirement: Network Security (5.3.1)
# VPC configuration with DNS support and custom CIDR block
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    {
      Name        = "founditure-${var.environment}-vpc"
      Environment = var.environment
    },
    var.tags
  )
}

# Requirement: High Availability (6.1)
# Public subnets across multiple availability zones
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block             = var.public_subnet_cidrs[count.index]
  availability_zone      = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name        = "founditure-${var.environment}-public-${var.availability_zones[count.index]}"
      Environment = var.environment
      Type        = "Public"
    },
    var.tags
  )
}

# Requirement: High Availability (6.1)
# Private subnets across multiple availability zones
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      Name        = "founditure-${var.environment}-private-${var.availability_zones[count.index]}"
      Environment = var.environment
      Type        = "Private"
    },
    var.tags
  )
}

# Requirement: Cloud Infrastructure (6.2)
# Internet Gateway for public subnet internet access
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name        = "founditure-${var.environment}-igw"
      Environment = var.environment
    },
    var.tags
  )
}

# Requirement: High Availability (6.1)
# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  domain = "vpc"

  tags = merge(
    {
      Name        = "founditure-${var.environment}-nat-eip-${count.index + 1}"
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.main]
}

# Requirement: High Availability (6.1)
# NAT Gateways for private subnet internet access
resource "aws_nat_gateway" "main" {
  count         = var.single_nat_gateway ? 1 : length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    {
      Name        = "founditure-${var.environment}-nat-${count.index + 1}"
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.main]
}

# Requirement: Network Security (5.3.1)
# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    {
      Name        = "founditure-${var.environment}-public-rt"
      Environment = var.environment
    },
    var.tags
  )
}

# Requirement: Network Security (5.3.1)
# Route tables for private subnets
resource "aws_route_table" "private" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(
    {
      Name        = "founditure-${var.environment}-private-rt-${count.index + 1}"
      Environment = var.environment
    },
    var.tags
  )
}

# Requirement: Network Security (5.3.1)
# Route table associations for public subnets
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Requirement: Network Security (5.3.1)
# Route table associations for private subnets
resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
}

# Requirement: Network Security (5.3.1)
# Security group for Application Load Balancer
resource "aws_security_group" "alb" {
  name        = "founditure-${var.environment}-alb-sg"
  description = "Security group for application load balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "founditure-${var.environment}-alb-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# Requirement: Network Security (5.3.1)
# Security group for ECS services
resource "aws_security_group" "ecs" {
  name        = "founditure-${var.environment}-ecs-sg"
  description = "Security group for ECS services"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "founditure-${var.environment}-ecs-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# Requirement: Cloud Infrastructure (6.2)
# Output the VPC ID for other modules
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

# Requirement: Cloud Infrastructure (6.2)
# Output public subnet IDs for ALB deployment
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

# Requirement: Cloud Infrastructure (6.2)
# Output private subnet IDs for service deployment
output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

# Requirement: Network Security (5.3.1)
# Output ALB security group ID
output "alb_security_group_id" {
  description = "Security group ID for the application load balancer"
  value       = aws_security_group.alb.id
}

# Requirement: Network Security (5.3.1)
# Output ECS security group ID
output "ecs_security_group_id" {
  description = "Security group ID for the ECS services"
  value       = aws_security_group.ecs.id
}