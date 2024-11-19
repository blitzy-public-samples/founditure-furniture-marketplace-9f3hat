#!/bin/bash

# Human Tasks:
# 1. Ensure Vault server is properly configured and accessible at vault.founditure.internal:8200
# 2. Verify AWS CLI credentials have sufficient permissions for IAM, KMS, and CloudWatch
# 3. Configure SNS topic for rotation notifications
# 4. Set up CloudWatch log group for secret rotation logs
# 5. Create Kubernetes service accounts with appropriate Vault authentication
# 6. Configure database users with permission to update credentials

# Required tool versions:
# - vault v1.13.0+
# - aws-cli v2.0+
# - jq v1.6+

# Requirement: 5.2.1 Encryption Standards - Implementation of automated key rotation
# Set environment variables and constants
VAULT_ADDR=${VAULT_ADDR:-"https://vault.founditure.internal:8200"}
AWS_REGION=${AWS_REGION:-"us-east-1"}
LOG_FILE=${LOG_FILE:-"/var/log/founditure/secret-rotation.log"}
SERVICES=${SERVICES:-'["ai-service", "listing-service", "messaging-service", "notification-service", "location-service", "gamification-service"]'}
ROTATION_TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
SNS_TOPIC_ARN="arn:aws:sns:${AWS_REGION}:$(aws sts get-caller-identity --query Account --output text):secret-rotation"

# Requirement: 5.3.2 Security Controls - Validation of prerequisites
check_prerequisites() {
    local exit_code=0

    # Check vault installation
    if ! vault version 2>&1 | grep -q "v1.13"; then
        echo "ERROR: Vault v1.13.0+ is required" | tee -a "$LOG_FILE"
        exit_code=1
    fi

    # Check AWS CLI installation
    if ! aws --version 2>&1 | grep -q "aws-cli/2"; then
        echo "ERROR: AWS CLI v2.0+ is required" | tee -a "$LOG_FILE"
        exit_code=1
    fi

    # Check jq installation
    if ! jq --version 2>&1 | grep -q "jq-1"; then
        echo "ERROR: jq v1.6+ is required" | tee -a "$LOG_FILE"
        exit_code=1
    fi

    # Verify environment variables
    if [[ -z "$VAULT_ADDR" ]]; then
        echo "ERROR: VAULT_ADDR environment variable is not set" | tee -a "$LOG_FILE"
        exit_code=1
    fi

    # Verify log file permissions
    if ! touch "$LOG_FILE" 2>/dev/null; then
        echo "ERROR: Cannot write to log file: $LOG_FILE" | tee -a "$LOG_FILE"
        exit_code=1
    fi

    # Verify Vault authentication
    if ! vault token lookup >/dev/null 2>&1; then
        echo "ERROR: Not authenticated to Vault" | tee -a "$LOG_FILE"
        exit_code=1
    fi

    # Verify AWS credentials
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        echo "ERROR: Invalid AWS credentials" | tee -a "$LOG_FILE"
        exit_code=1
    fi

    return $exit_code
}

# Requirement: 5.2.1 Encryption Standards - Service-specific secret rotation
rotate_service_secrets() {
    local service_name=$1
    local exit_code=0

    echo "Starting secret rotation for ${service_name} at $(date -u)" | tee -a "$LOG_FILE"

    # Validate service name
    if ! echo "$SERVICES" | jq -e ".[] | select(. == \"${service_name}\")" >/dev/null; then
        echo "ERROR: Invalid service name: ${service_name}" | tee -a "$LOG_FILE"
        return 1
    }

    # Generate new service credentials
    local new_api_key=$(openssl rand -hex 32)
    local new_secret_key=$(openssl rand -base64 48)

    # Store new credentials in Vault
    if ! vault kv put "secret/founditure/${service_name}/credentials" \
        api_key="$new_api_key" \
        secret_key="$new_secret_key" \
        rotation_timestamp="$ROTATION_TIMESTAMP"; then
        echo "ERROR: Failed to store new credentials for ${service_name}" | tee -a "$LOG_FILE"
        exit_code=1
    fi

    # Trigger Kubernetes service reload
    if ! kubectl rollout restart deployment "${service_name}" -n founditure; then
        echo "WARNING: Failed to restart ${service_name} deployment" | tee -a "$LOG_FILE"
    fi

    return $exit_code
}

# Requirement: 5.3.2 Security Controls - AWS IAM key rotation
rotate_aws_keys() {
    local service_name=$1
    local exit_code=0

    echo "Rotating AWS IAM keys for ${service_name}" | tee -a "$LOG_FILE"

    # Create new IAM access key
    local new_key_output
    new_key_output=$(aws iam create-access-key --user-name "founditure-${service_name}")
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to create new IAM key for ${service_name}" | tee -a "$LOG_FILE"
        return 1
    fi

    # Extract new credentials
    local access_key=$(echo "$new_key_output" | jq -r '.AccessKey.AccessKeyId')
    local secret_key=$(echo "$new_key_output" | jq -r '.AccessKey.SecretAccessKey')

    # Store new credentials in Vault
    if ! vault kv put "secret/founditure/${service_name}/aws" \
        access_key="$access_key" \
        secret_key="$secret_key" \
        rotation_timestamp="$ROTATION_TIMESTAMP"; then
        echo "ERROR: Failed to store AWS credentials for ${service_name}" | tee -a "$LOG_FILE"
        exit_code=1
    fi

    # Delete old access key after delay to ensure propagation
    sleep 30
    local old_key=$(aws iam list-access-keys --user-name "founditure-${service_name}" | jq -r '.AccessKeyMetadata[0].AccessKeyId')
    if [ "$old_key" != "$access_key" ]; then
        aws iam delete-access-key --user-name "founditure-${service_name}" --access-key-id "$old_key"
    fi

    return $exit_code
}

# Requirement: 5.2.1 Encryption Standards - Database credential rotation
rotate_database_credentials() {
    local service_name=$1
    local exit_code=0

    echo "Rotating database credentials for ${service_name}" | tee -a "$LOG_FILE"

    # Generate new database password
    local new_password=$(openssl rand -base64 32)
    local db_user="founditure_${service_name//-/_}"

    # Update database user password
    if ! PGPASSWORD="$POSTGRES_ADMIN_PASSWORD" psql -h "$DB_HOST" -U "$POSTGRES_ADMIN_USER" -d "founditure" \
        -c "ALTER USER ${db_user} WITH PASSWORD '${new_password}';" ; then
        echo "ERROR: Failed to update database password for ${service_name}" | tee -a "$LOG_FILE"
        exit_code=1
    fi

    # Store new credentials in Vault
    if ! vault kv put "secret/founditure/${service_name}/database" \
        username="$db_user" \
        password="$new_password" \
        rotation_timestamp="$ROTATION_TIMESTAMP"; then
        echo "ERROR: Failed to store database credentials for ${service_name}" | tee -a "$LOG_FILE"
        exit_code=1
    fi

    return $exit_code
}

# Requirement: 5.3.3 Security Compliance - Rotation status notifications
notify_rotation_status() {
    local service_name=$1
    local status=$2
    local exit_code=0

    local message=$(cat <<EOF
{
    "service": "${service_name}",
    "status": "${status}",
    "timestamp": "${ROTATION_TIMESTAMP}",
    "environment": "production"
}
EOF
)

    # Send SNS notification
    if ! aws sns publish \
        --topic-arn "$SNS_TOPIC_ARN" \
        --message "$message" \
        --region "$AWS_REGION"; then
        echo "ERROR: Failed to send rotation notification for ${service_name}" | tee -a "$LOG_FILE"
        exit_code=1
    fi

    # Update CloudWatch metrics
    aws cloudwatch put-metric-data \
        --namespace "Founditure/SecretRotation" \
        --metric-name "RotationStatus" \
        --dimensions Service="${service_name}" \
        --value "$([[ $status == "success" ]] && echo 1 || echo 0)" \
        --region "$AWS_REGION"

    return $exit_code
}

# Main execution
main() {
    echo "Starting secret rotation process at $(date -u)" | tee -a "$LOG_FILE"

    # Check prerequisites
    if ! check_prerequisites; then
        echo "ERROR: Prerequisites check failed" | tee -a "$LOG_FILE"
        exit 1
    fi

    # Iterate through services
    echo "$SERVICES" | jq -r '.[]' | while read -r service; do
        echo "Processing ${service}" | tee -a "$LOG_FILE"
        
        local rotation_status="success"

        # Rotate service secrets
        if ! rotate_service_secrets "$service"; then
            rotation_status="failed"
        fi

        # Rotate AWS keys
        if ! rotate_aws_keys "$service"; then
            rotation_status="failed"
        fi

        # Rotate database credentials
        if ! rotate_database_credentials "$service"; then
            rotation_status="failed"
        fi

        # Send notification
        notify_rotation_status "$service" "$rotation_status"
    done

    echo "Secret rotation process completed at $(date -u)" | tee -a "$LOG_FILE"
}

# Execute main function
main "$@"