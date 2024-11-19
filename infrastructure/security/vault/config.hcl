# Human Tasks:
# 1. Generate and configure AWS KMS key with alias 'vault-unseal-key' in us-east-1 region
# 2. Configure AWS credentials for VAULT_AWS_ACCESS_KEY and VAULT_AWS_SECRET_KEY
# 3. Ensure TLS certificates are properly generated and placed in /vault/tls directory
# 4. Set up proper file permissions for audit log directory
# 5. Configure DNS for vault.founditure.internal

# Requirement: 5.2.1 Encryption Standards - Storage and seal configuration
storage "raft" {
    path = "/vault/data"
    node_id = "node-a.founditure.internal"
    retry_join {
        leader_api_addr = "https://vault-0.vault-internal:8200"
        leader_ca_cert_file = "/vault/tls/ca.crt"
    }
    performance_multiplier = 1
}

# Requirement: 5.2.1 Encryption Standards - TLS configuration for secure communication
listener "tcp" {
    address = "0.0.0.0:8200"
    tls_disable = "false"
    tls_cert_file = "/vault/tls/tls.crt"
    tls_key_file = "/vault/tls/tls.key"
    tls_min_version = "tls12"
    tls_prefer_server_cipher_suites = "true"
}

# Requirement: 5.2.1 Encryption Standards - Auto-unseal configuration using AWS KMS
seal "awskms" {
    region = "us-east-1"
    kms_key_id = "alias/vault-unseal-key"
    endpoint = "https://kms.us-east-1.amazonaws.com"
}

# Requirement: 5.1.2 Authorization Model - Authentication methods configuration
auth {
    # Kubernetes authentication configuration
    kubernetes {
        path = "kubernetes"
        kubernetes_host = "https://kubernetes.default.svc"
        kubernetes_ca_cert = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
        token_reviewer_jwt = "/var/run/secrets/kubernetes.io/serviceaccount/token"
        disable_iss_validation = "true"
    }

    # AWS authentication configuration
    aws {
        path = "aws"
        access_key = "VAULT_AWS_ACCESS_KEY"
        secret_key = "VAULT_AWS_SECRET_KEY"
        region = "us-east-1"
        iam_server_id_header_value = "vault.founditure.internal"
    }
}

# Requirement: 5.3.2 Security Controls - Audit logging configuration
audit {
    file {
        path = "file"
        file_path = "/vault/logs/audit.log"
        log_raw = "false"
        format = "json"
        mode = "0600"
    }
}

# Service-specific policy paths
# These paths will be used to mount policies defined in service-policies.json
path "auth/kubernetes/role/ai-service" {
    capabilities = ["create", "read", "update", "delete"]
}

path "auth/kubernetes/role/listing-service" {
    capabilities = ["create", "read", "update", "delete"]
}

# System configuration paths
path "sys/auth" {
    capabilities = ["read", "list"]
}

path "sys/policies/acl" {
    capabilities = ["read", "list"]
}

path "sys/mounts" {
    capabilities = ["read", "list"]
}

# Health check path
path "sys/health" {
    capabilities = ["read", "sudo"]
}

# Enable telemetry for monitoring
telemetry {
    disable_hostname = true
    prometheus_retention_time = "24h"
    disable_hostname = true
}

# Disable mlock as we're running in a container environment
disable_mlock = true

# API configuration
api_addr = "https://vault.founditure.internal:8200"
cluster_addr = "https://vault-0.vault-internal:8201"

# Default maximum lease TTL for tokens and secrets
max_lease_ttl = "768h"
default_lease_ttl = "768h"