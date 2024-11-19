#!/bin/bash

# Required tools and versions:
# - openssl v1.1.1+ (for TLS 1.3 support)
# - aws-cli v2.0+ (for ACM integration)

# Human Tasks:
# 1. Ensure OpenSSL 1.1.1+ is installed for TLS 1.3 support
# 2. Configure AWS CLI with appropriate credentials and permissions
# 3. Create DNS records for domain validation when prompted
# 4. Backup generated root CA and private keys in secure location
# 5. Update service trust relationships in IAM if needed

# Global configuration
SSL_KEY_SIZE=4096
SSL_DAYS_VALID=365
CA_DAYS_VALID=3650
CERT_OUTPUT_DIR="/etc/ssl/founditure"
AWS_REGION="us-east-1"

# Service roles from service-roles.json
VALID_SERVICES=(
    "ai-service"
    "listing-service"
    "messaging-service"
    "notification-service"
    "location-service"
    "gamification-service"
)

# Implements requirement 3.3.1 API Architecture/Protocol - TLS 1.3 configuration
OPENSSL_CONFIG="
[req]
default_bits = $SSL_KEY_SIZE
default_md = sha512
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[req_distinguished_name]
C = US
ST = California
L = San Francisco
O = Founditure
OU = Security
CN = \$ENV::CERT_CN

[v3_ca]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[v3_leaf]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
"

# Validate input parameters
validate_params() {
    local params=("$@")
    for param in "${params[@]}"; do
        if [ -z "$param" ]; then
            echo "Error: Missing required parameter"
            return 1
        fi
    done
    return 0
}

# Implements requirement 5.2.1 Encryption Standards/In Transit
generate_root_ca() {
    local output_dir="$1"
    local ca_name="$2"

    validate_params "$output_dir" "$ca_name" || return 1
    
    mkdir -p "$output_dir"
    
    # Generate CA private key with 4096-bit RSA
    export CERT_CN="Founditure Root CA - $ca_name"
    openssl genrsa -out "$output_dir/root-ca.key" $SSL_KEY_SIZE
    
    # Generate CA certificate
    openssl req -new -x509 -sha512 \
        -key "$output_dir/root-ca.key" \
        -out "$output_dir/root-ca.crt" \
        -days $CA_DAYS_VALID \
        -config <(echo "$OPENSSL_CONFIG")
    
    # Set secure permissions
    chmod 600 "$output_dir/root-ca.key"
    chmod 644 "$output_dir/root-ca.crt"
    
    # Verify TLS 1.3 compatibility
    openssl x509 -text -noout -in "$output_dir/root-ca.crt" | grep -q "Signature Algorithm: sha512"
    return $?
}

# Implements requirement 3.3.1 API Architecture/Protocol
generate_service_cert() {
    local service_name="$1"
    local domain="$2"
    local environment="$3"
    
    validate_params "$service_name" "$domain" "$environment" || return 1
    
    # Validate service name
    local valid_service=false
    for svc in "${VALID_SERVICES[@]}"; do
        if [ "$service_name" == "$svc" ]; then
            valid_service=true
            break
        fi
    done
    
    if [ "$valid_service" != true ]; then
        echo "Error: Invalid service name"
        return 1
    fi
    
    local cert_dir="$CERT_OUTPUT_DIR/$environment/$service_name"
    mkdir -p "$cert_dir"
    
    # Generate service private key
    openssl genrsa -out "$cert_dir/$service_name.key" $SSL_KEY_SIZE
    
    # Generate CSR with SANs
    export CERT_CN="$service_name.$domain"
    openssl req -new -sha512 \
        -key "$cert_dir/$service_name.key" \
        -out "$cert_dir/$service_name.csr" \
        -config <(echo "$OPENSSL_CONFIG")
    
    # Sign with root CA
    openssl x509 -req -sha512 \
        -in "$cert_dir/$service_name.csr" \
        -CA "$CERT_OUTPUT_DIR/root-ca.crt" \
        -CAkey "$CERT_OUTPUT_DIR/root-ca.key" \
        -CAcreateserial \
        -out "$cert_dir/$service_name.crt" \
        -days $SSL_DAYS_VALID
    
    # Generate PKCS#12 bundle
    openssl pkcs12 -export \
        -in "$cert_dir/$service_name.crt" \
        -inkey "$cert_dir/$service_name.key" \
        -out "$cert_dir/$service_name.p12" \
        -name "$service_name" \
        -passout pass:
    
    # Upload to ACM
    cert_arn=$(aws acm import-certificate \
        --certificate fileb://"$cert_dir/$service_name.crt" \
        --private-key fileb://"$cert_dir/$service_name.key" \
        --certificate-chain fileb://"$CERT_OUTPUT_DIR/root-ca.crt" \
        --region "$AWS_REGION" \
        --tags Key=Service,Value="$service_name" Key=Environment,Value="$environment" \
        --output text)
    
    echo "Certificate ARN: $cert_arn"
    return 0
}

# Implements requirement 6.2 CLOUD SERVICES/CloudFront
generate_cloudfront_cert() {
    local domain_name="$1"
    local region="$2"
    
    validate_params "$domain_name" "$region" || return 1
    
    # CloudFront certificates must be in us-east-1
    if [ "$region" != "us-east-1" ]; then
        echo "Error: CloudFront certificates must be in us-east-1"
        return 1
    }
    
    # Request certificate
    cert_arn=$(aws acm request-certificate \
        --domain-name "$domain_name" \
        --validation-method DNS \
        --key-algorithm RSA_4096 \
        --region "$region" \
        --tags Key=Service,Value="cloudfront" \
        --output text)
    
    echo "Certificate ARN: $cert_arn"
    
    # Wait for DNS validation records
    sleep 30
    
    # Get DNS validation records
    aws acm describe-certificate \
        --certificate-arn "$cert_arn" \
        --region "$region" \
        --query 'Certificate.DomainValidationOptions[].ResourceRecord'
    
    echo "Please create the above DNS records and press Enter to continue..."
    read
    
    # Poll validation status
    while true; do
        status=$(aws acm describe-certificate \
            --certificate-arn "$cert_arn" \
            --region "$region" \
            --query 'Certificate.Status' \
            --output text)
        
        if [ "$status" == "ISSUED" ]; then
            break
        elif [ "$status" == "FAILED" ]; then
            echo "Certificate validation failed"
            return 1
        fi
        
        echo "Waiting for validation... Current status: $status"
        sleep 30
    done
    
    return 0
}

# Main script execution guard
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        "root-ca")
            generate_root_ca "$2" "$3"
            ;;
        "service")
            generate_service_cert "$2" "$3" "$4"
            ;;
        "cloudfront")
            generate_cloudfront_cert "$2" "$3"
            ;;
        *)
            echo "Usage:"
            echo "  $0 root-ca <output_dir> <ca_name>"
            echo "  $0 service <service_name> <domain> <environment>"
            echo "  $0 cloudfront <domain_name> <region>"
            exit 1
            ;;
    esac
fi