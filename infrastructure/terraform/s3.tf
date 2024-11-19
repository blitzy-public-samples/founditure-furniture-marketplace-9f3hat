# Human Tasks:
# 1. Ensure AWS KMS key permissions are properly configured for S3 bucket encryption
# 2. Verify CORS settings align with frontend application domains
# 3. Review lifecycle rules based on actual media retention requirements
# 4. Confirm CloudFront distribution is properly configured to access the S3 bucket

# AWS Provider - version 5.0+
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Requirement: Object Storage
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
# Description: S3 for scalable storage of user-generated content and media files
resource "aws_s3_bucket" "media" {
  bucket_prefix = "founditure-media-${var.environment}"
  force_destroy = false
  tags          = var.tags
}

# Requirement: Data Security
# Location: 5. SECURITY CONSIDERATIONS/5.2 DATA SECURITY/Encryption Standards
# Description: Server-side encryption for media files with AWS KMS integration
resource "aws_s3_bucket_server_side_encryption_configuration" "media_encryption" {
  bucket = aws_s3_bucket.media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

# Requirement: Object Storage
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
# Description: Enable versioning for data protection and recovery
resource "aws_s3_bucket_versioning" "media_versioning" {
  bucket = aws_s3_bucket.media.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Requirement: Data Security
# Location: 5. SECURITY CONSIDERATIONS/5.2 DATA SECURITY/Encryption Standards
# Description: Block all public access to ensure secure access control
resource "aws_s3_bucket_public_access_block" "media_access" {
  bucket = aws_s3_bucket.media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Requirement: Media Delivery
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
# Description: Configure CORS for secure media access from web applications
resource "aws_s3_bucket_cors_configuration" "media_cors" {
  bucket = aws_s3_bucket.media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Requirement: Object Storage
# Location: 6. INFRASTRUCTURE/6.2 CLOUD SERVICES/AWS Service Stack
# Description: Implement lifecycle rules for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "media_lifecycle" {
  bucket = aws_s3_bucket.media.id

  rule {
    id     = "media_lifecycle"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
  }
}

# Output the bucket name and ARN for reference by other resources
output "media_bucket_name" {
  description = "Name of the created media S3 bucket"
  value       = aws_s3_bucket.media.id
}

output "media_bucket_arn" {
  description = "ARN of the created media S3 bucket"
  value       = aws_s3_bucket.media.arn
}