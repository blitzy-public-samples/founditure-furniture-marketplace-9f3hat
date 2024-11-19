#!/bin/bash

# Required tools and versions:
# - aws-cli v2.0+ (for ACM certificate management)
# - openssl v1.1.1+ (for TLS 1.3 support)
# - certbot v2.0+ (for Let's Encrypt certificate generation)

# Human Tasks:
# 1. Ensure AWS CLI is configured with appropriate credentials and permissions
# 2. Verify OpenSSL 1.1.1+ is installed for TLS 1.3 support
# 3. Configure DNS records for domain validation when prompted
# 4. Backup generated certificates and private keys in secure location
# 5. Review certificate rotation schedule and monitoring

# Source the core certificate generation functions
# shellcheck source=../security/ssl/generate-certs.sh
source "$(dirname "${BASH_SOURCE[0]}")/../security/ssl/generate-certs.sh"

# Global variables from specification
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
CERT_OUTPUT_DIR="/etc/ssl/founditure"
LOG_FILE="/var/log/founditure/ssl-generation.log"
DOMAINS=["founditure.com", "*.founditure.com", "api.founditure.com", "cdn.founditure.com"]
ENVIRONMENTS=["dev", "staging", "prod"]
SSL_KEY_SIZE=4096
SSL_DAYS_VALID=365

# Implements requirement: Data Security - TLS 1.3 encryption for securing data in transit
setup_logging() {
    local log_dir
    log_dir=$(dirname "$LOG_FILE")
    
    # Create log directory if it doesn't exist
    mkdir -p "$log_dir"
    
    # Initialize log file with rotation
    if ! [ -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
    fi
    
    # Configure log rotation
    cat > "/etc/logrotate.d/founditure-ssl" << EOF
$LOG_FILE {
    weekly
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
}
EOF

    # Log script initialization
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SSL certificate generation script initialized" >> "$LOG_FILE"
}

# Implements requirement: Security Controls - SSL termination and certificate management
validate_prerequisites() {
    local aws_version
    local openssl_version
    local certbot_version
    
    # Check AWS CLI
    if ! aws_version=$(aws --version 2>&1); then
        echo "Error: AWS CLI not installed" | tee -a "$LOG_FILE"
        return 1
    fi
    if ! [[ $aws_version =~ aws-cli/2\. ]]; then
        echo "Error: AWS CLI version 2.0+ required" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Check OpenSSL with TLS 1.3 support
    if ! openssl_version=$(openssl version); then
        echo "Error: OpenSSL not installed" | tee -a "$LOG_FILE"
        return 1
    fi
    if ! [[ $openssl_version =~ 1\.1\.[1-9] ]]; then
        echo "Error: OpenSSL version 1.1.1+ required for TLS 1.3 support" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Check Certbot
    if ! certbot_version=$(certbot --version 2>&1); then
        echo "Error: Certbot not installed" | tee -a "$LOG_FILE"
        return 1
    fi
    if ! [[ $certbot_version =~ 2\. ]]; then
        echo "Error: Certbot version 2.0+ required" | tee -a "$LOG_FILE"
        return 1
    }
    
    # Create certificate output directory
    mkdir -p "$CERT_OUTPUT_DIR"
    
    return 0
}

# Implements requirement: Production Environment - Multi-region deployment with SSL/TLS security
generate_environment_certs() {
    local environment="$1"
    local success=true
    
    echo "Generating certificates for environment: $environment" >> "$LOG_FILE"
    
    # Generate root CA for internal PKI
    if ! generate_root_ca "$CERT_OUTPUT_DIR" "Founditure-$environment"; then
        echo "Error: Failed to generate root CA for $environment" >> "$LOG_FILE"
        return 1
    fi
    
    # Generate service certificates
    for domain in "${DOMAINS[@]}"; do
        if [[ $domain == *"api."* ]]; then
            if ! generate_service_cert "api-service" "$domain" "$environment"; then
                echo "Error: Failed to generate API service certificate for $domain" >> "$LOG_FILE"
                success=false
            fi
        elif [[ $domain == *"cdn."* ]]; then
            if ! generate_cloudfront_cert "$domain" "us-east-1"; then
                echo "Error: Failed to generate CloudFront certificate for $domain" >> "$LOG_FILE"
                success=false
            fi
        fi
    done
    
    # Verify certificate chain and parameters
    for cert in "$CERT_OUTPUT_DIR/$environment"/*.crt; do
        if [ -f "$cert" ]; then
            if ! openssl x509 -in "$cert" -text -noout | grep -q "TLS 1.3"; then
                echo "Warning: Certificate $cert may not support TLS 1.3" >> "$LOG_FILE"
                success=false
            fi
        fi
    done
    
    if [ "$success" = true ]; then
        echo "Successfully generated all certificates for $environment" >> "$LOG_FILE"
        return 0
    else
        return 1
    fi
}

# Main script execution
main() {
    local exit_code=0
    
    setup_logging
    
    if ! validate_prerequisites; then
        echo "Failed to validate prerequisites" >> "$LOG_FILE"
        return 1
    fi
    
    for env in "${ENVIRONMENTS[@]}"; do
        if ! generate_environment_certs "$env"; then
            echo "Failed to generate certificates for environment: $env" >> "$LOG_FILE"
            exit_code=1
        fi
    done
    
    # Cleanup temporary files
    find "$CERT_OUTPUT_DIR" -name "*.csr" -delete
    find "$CERT_OUTPUT_DIR" -name "*.srl" -delete
    
    echo "Certificate generation completed with status: $exit_code" >> "$LOG_FILE"
    return $exit_code
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi