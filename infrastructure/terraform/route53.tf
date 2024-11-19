# Human Tasks:
# 1. Verify domain ownership and ensure domain is registered in Route 53 or transferable
# 2. Configure domain registrar nameservers with the Route 53 nameservers after zone creation
# 3. Validate SSL certificates are properly issued for all domains/subdomains
# 4. Review health check settings and adjust thresholds based on application requirements
# 5. Ensure API load balancer exists and is properly configured for the API endpoint

# AWS Provider - version 5.0+
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Requirement: Global DNS Management
# Location: 6.2 CLOUD SERVICES/AWS Service Stack
# Description: Primary hosted zone for the Founditure domain
resource "aws_route53_zone" "main" {
  name    = "founditure.com"
  comment = "Main domain for Founditure platform"

  tags = {
    Environment = var.environment
    Project     = "Founditure"
    ManagedBy   = "Terraform"
  }
}

# Requirement: High Availability
# Location: 2. SYSTEM ARCHITECTURE/2.1 High-Level Architecture
# Description: Health check for API endpoint monitoring
resource "aws_route53_health_check" "api" {
  fqdn              = "api.founditure.com"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = "3"
  request_interval  = "30"
  measure_latency   = true

  regions = [
    "us-east-1",
    "us-west-2",
    "us-west-1"
  ]

  tags = {
    Name        = "founditure-api-health-check"
    Environment = var.environment
    Project     = "Founditure"
    ManagedBy   = "Terraform"
  }
}

# Requirement: Geographic Coverage
# Location: 1.3 Scope/Implementation Boundaries
# Description: Main domain A record pointing to CloudFront distribution
resource "aws_route53_record" "main" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "founditure.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.founditure_distribution.domain_name
    zone_id               = aws_cloudfront_distribution.founditure_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

# Requirement: Geographic Coverage
# Location: 1.3 Scope/Implementation Boundaries
# Description: CDN subdomain A record
resource "aws_route53_record" "cdn" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "cdn.founditure.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.founditure_distribution.domain_name
    zone_id               = aws_cloudfront_distribution.founditure_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

# Requirement: High Availability
# Location: 2. SYSTEM ARCHITECTURE/2.1 High-Level Architecture
# Description: API subdomain A record with health check and failover routing
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.founditure.com"
  type    = "A"

  alias {
    name                   = aws_lb.api.dns_name
    zone_id               = aws_lb.api.zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.api.id
  set_identifier  = "primary"
  
  failover_routing_policy {
    type = "PRIMARY"
  }
}

# Requirement: Global DNS Management
# Location: 6.2 CLOUD SERVICES/AWS Service Stack
# Description: Export hosted zone ID for other configurations
output "route53_zone_id" {
  description = "ID of the main Route 53 hosted zone"
  value       = aws_route53_zone.main.zone_id
}

# Requirement: Global DNS Management
# Location: 6.2 CLOUD SERVICES/AWS Service Stack
# Description: Export nameservers for domain configuration
output "route53_zone_nameservers" {
  description = "Nameservers for the main Route 53 hosted zone"
  value       = aws_route53_zone.main.name_servers
}