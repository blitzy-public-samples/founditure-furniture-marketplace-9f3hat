# Requirement: System Monitoring
# Location: 2. SYSTEM ARCHITECTURE/2.4 Cross-Cutting Concerns/2.4.1 System Monitoring
output "prometheus_endpoint" {
  value       = "http://${monitoring_resources.value.prometheus_endpoint}"
  description = "Endpoint URL for Prometheus metrics collection server"
}

output "grafana_endpoint" {
  value       = "http://${monitoring_resources.value.grafana_endpoint}"
  description = "Endpoint URL for Grafana metrics visualization dashboard"
}

output "elasticsearch_endpoint" {
  value       = "http://${monitoring_resources.value.elasticsearch_endpoint}"
  description = "Endpoint URL for Elasticsearch log storage and search service"
}

output "kibana_endpoint" {
  value       = "http://${monitoring_resources.value.kibana_endpoint}"
  description = "Endpoint URL for Kibana log visualization dashboard"
}

output "jaeger_endpoint" {
  value       = "http://${monitoring_resources.value.jaeger_endpoint}"
  description = "Endpoint URL for Jaeger distributed tracing UI"
}

# Requirement: Performance Metrics
# Location: 4. TECHNOLOGY STACK/4.4 THIRD-PARTY SERVICES
output "prometheus_security_group_id" {
  value       = aws_security_group.monitoring.id
  description = "Security group ID for Prometheus server network access"
}

output "grafana_security_group_id" {
  value       = aws_security_group.monitoring.id
  description = "Security group ID for Grafana dashboard network access"
}

output "elk_security_group_id" {
  value       = aws_security_group.monitoring.id
  description = "Security group ID for ELK stack components network access"
}

# Requirement: System Monitoring
# Location: 2. SYSTEM ARCHITECTURE/2.4 Cross-Cutting Concerns/2.4.1 System Monitoring
output "monitoring_subnet_ids" {
  value       = var.subnet_ids
  description = "List of subnet IDs where monitoring components are deployed"
}

output "cloudwatch_log_groups" {
  value = {
    prometheus = aws_cloudwatch_log_group.monitoring.name
    grafana    = "${aws_cloudwatch_log_group.monitoring.name}/grafana"
    elastic    = "${aws_cloudwatch_log_group.monitoring.name}/elastic"
    jaeger     = "${aws_cloudwatch_log_group.monitoring.name}/jaeger"
  }
  description = "Map of CloudWatch log group names for each monitoring component"
}