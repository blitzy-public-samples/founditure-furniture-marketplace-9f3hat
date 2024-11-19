# Human Tasks:
# 1. Review and adjust rate limiting thresholds based on expected traffic patterns
# 2. Configure additional IP addresses in the blacklist IP set based on security requirements
# 3. Verify WAF logging configuration aligns with security monitoring requirements
# 4. Ensure CloudFront distribution exists before WAF association

# AWS Provider configuration
# Provider version: ~> 5.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Requirement: Network Security
# Location: 5. SECURITY CONSIDERATIONS/5.3.1 Network Security
# Creates WAF Web ACL with OWASP Top 10 protections and rate limiting
resource "aws_wafv2_web_acl" "founditure_waf" {
  name        = "founditure-${var.environment}-waf"
  description = "WAF rules for Founditure application implementing OWASP security standards"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Configure WAF metrics and logging
  visibility_config {
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled  = true
    metric_name              = "FounditureWAFMetrics-${var.environment}"
  }

  # Requirement: API Security
  # Location: 5. SECURITY CONSIDERATIONS/5.3.3 Security Compliance
  # AWS Managed Rules - Common Rule Set (CRS)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled  = true
      metric_name              = "AWSManagedRulesCommonRuleSetMetric"
    }
  }

  # Requirement: API Security
  # Location: 5. SECURITY CONSIDERATIONS/5.3.3 Security Compliance
  # AWS Managed Rules - Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled  = true
      metric_name              = "AWSManagedRulesKnownBadInputsRuleSetMetric"
    }
  }

  # Requirement: Network Security
  # Location: 5. SECURITY CONSIDERATIONS/5.3.1 Network Security
  # IP-based Rate Limiting Rule
  rule {
    name     = "IPRateLimit"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled  = true
      metric_name              = "IPRateLimitMetric"
    }
  }

  tags = var.tags
}

# Requirement: Cloud Security
# Location: 6.2 CLOUD SERVICES/AWS Service Stack
# WAF Web ACL Association with CloudFront
resource "aws_wafv2_web_acl_association" "founditure_waf_association" {
  resource_arn = aws_cloudfront_distribution.founditure_cdn.arn
  web_acl_arn  = aws_wafv2_web_acl.founditure_waf.arn
}

# Requirement: Network Security
# Location: 5. SECURITY CONSIDERATIONS/5.3.1 Network Security
# IP Set for Blacklisting
resource "aws_wafv2_ip_set" "founditure_blacklist" {
  name               = "founditure-${var.environment}-blacklist"
  description        = "Blacklisted IP addresses for enhanced security"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = []  # Empty by default, to be populated based on security requirements

  tags = var.tags
}

# Output WAF Web ACL ARN for use in other configurations
output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL for CloudFront association"
  value       = aws_wafv2_web_acl.founditure_waf.arn
}

# Output WAF Web ACL ID for resource references
output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL for resource references"
  value       = aws_wafv2_web_acl.founditure_waf.id
}