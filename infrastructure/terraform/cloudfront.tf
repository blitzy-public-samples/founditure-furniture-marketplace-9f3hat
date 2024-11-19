# Human Tasks:
# 1. Verify that the ACM certificate for cdn.founditure.com is created and validated
# 2. Ensure DNS records are configured to point cdn.founditure.com to the CloudFront distribution
# 3. Confirm WAF web ACL exists with appropriate rules for the environment
# 4. Review price class selection based on target geographical regions
# 5. Validate custom error page (404.html) exists in the S3 bucket

# AWS Provider - version 5.0+
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Requirement: Content Delivery Network
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
# Description: CloudFront Origin Access Identity for secure S3 bucket access
resource "aws_cloudfront_origin_access_identity" "founditure_oai" {
  comment = "Origin Access Identity for Founditure media bucket"
}

# Requirement: Content Delivery Network
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
# Description: Reference existing WAF ACL for distribution protection
data "aws_wafv2_web_acl" "founditure_waf" {
  name  = "founditure-waf-${var.environment}"
  scope = "REGIONAL"
}

# Requirement: Media Distribution & Global Reach
# Location: 2. SYSTEM ARCHITECTURE/2.2.1 Core Components
# Description: CloudFront distribution for global content delivery
resource "aws_cloudfront_distribution" "founditure_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Founditure CDN distribution"
  default_root_object = "index.html"
  price_class         = "PriceClass_100" # North America and Europe coverage
  web_acl_id          = data.aws_wafv2_web_acl.founditure_waf.arn
  aliases             = ["cdn.founditure.com"]

  origin {
    domain_name = aws_s3_bucket.media.bucket_regional_domain_name
    origin_id   = "S3-founditure-media"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.founditure_oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-founditure-media"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600  # 1 hour
    max_ttl                = 86400 # 24 hours
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cdn.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/404.html"
  }

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = "Founditure"
      ManagedBy   = "Terraform"
    }
  )
}

# Requirement: Content Delivery Network
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
# Description: Output CloudFront distribution details for other resources
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.founditure_distribution.id
}

output "cloudfront_distribution_domain" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.founditure_distribution.domain_name
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.founditure_distribution.arn
}