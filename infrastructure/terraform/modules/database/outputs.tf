# Requirement: Database Infrastructure (6.2 Cloud Services)
# Output definitions for RDS PostgreSQL instance connection details
output "rds_endpoint" {
  description = "Connection endpoint for the RDS PostgreSQL instance"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "DNS address of the RDS PostgreSQL instance"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "Port number for the RDS PostgreSQL instance"
  value       = aws_db_instance.main.port
}

output "rds_arn" {
  description = "ARN of the RDS PostgreSQL instance"
  value       = aws_db_instance.main.arn
}

# Requirement: High Availability (6.1 DEPLOYMENT ENVIRONMENT)
# Output definitions for MongoDB Atlas cluster connection details
output "mongodb_connection_strings" {
  description = "Connection strings for the MongoDB Atlas cluster"
  value       = mongodbatlas_cluster.main.connection_strings
  sensitive   = true
}

output "mongodb_cluster_id" {
  description = "Cluster ID of the MongoDB Atlas deployment"
  value       = mongodbatlas_cluster.main.cluster_id
}

output "mongodb_uri" {
  description = "Primary connection URI for the MongoDB Atlas cluster"
  value       = mongodbatlas_cluster.main.mongo_uri
  sensitive   = true
}

output "mongodb_uri_updated" {
  description = "Updated connection URI for the MongoDB Atlas cluster"
  value       = mongodbatlas_cluster.main.mongo_uri_updated
  sensitive   = true
}

# Requirement: Data Security (5.2 Data Security)
# Output definitions for database security group details
output "db_security_group_id" {
  description = "ID of the security group controlling database access"
  value       = aws_security_group.main.id
}

output "db_security_group_name" {
  description = "Name of the security group controlling database access"
  value       = aws_security_group.main.name
}

output "db_security_group_arn" {
  description = "ARN of the security group controlling database access"
  value       = aws_security_group.main.arn
}