# Requirement: Data Security (5.2.1 Encryption Standards)
# Exposes KMS key identifiers for data encryption management
output "kms_key_id" {
  description = "ID of the KMS key used for data encryption"
  value       = aws_kms_key.main.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for data encryption"
  value       = aws_kms_key.main.arn
}

# Requirement: Network Security (5.3.1 Network Security)
# Exposes WAF ACL identifiers for network protection configuration
output "waf_web_acl_id" {
  description = "ID of the WAF web ACL protecting application endpoints"
  value       = aws_wafv2_web_acl.main.id
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF web ACL protecting application endpoints"
  value       = aws_wafv2_web_acl.main.arn
}

# Requirement: Network Security (5.3.1 Network Security)
# Exposes security group identifiers for network access control
output "security_group_id" {
  description = "ID of the security group for application services"
  value       = aws_security_group.main.id
}

output "security_group_name" {
  description = "Name of the security group for application services"
  value       = aws_security_group.main.name
}

# Requirement: Authentication and Authorization (5.1.2 Authorization Model)
# Exposes IAM role identifiers for service authentication
output "service_role_arns" {
  description = "Map of service names to their IAM role ARNs"
  value       = local.service_role_arns
}

output "service_role_names" {
  description = "Map of service names to their IAM role names"
  value       = local.service_role_names
}