#!/bin/bash

# Required Human Tasks:
# 1. Ensure AWS CLI v2.0+ is installed and configured with appropriate credentials
# 2. Install jq 1.6+ for JSON processing
# 3. Install PostgreSQL client tools v15
# 4. Configure AWS KMS key permissions for the service account
# 5. Set up SNS topic for backup notifications
# 6. Verify S3 bucket permissions and lifecycle policies

# REQ: Data Protection - Implements encrypted backup mechanisms using AES-256 encryption with AWS KMS integration
# REQ: Business Continuity - Provides automated and manual backup capabilities with validation
# REQ: High Availability - Supports backup operations across multiple AZs with redundancy

# External Dependencies:
# aws-cli v2.0+
# jq v1.6+
# postgresql-client v15

set -euo pipefail

# Load backup policy configuration
POLICY_FILE="/infrastructure/backup/backup-policy.json"
if [[ ! -f "${POLICY_FILE}" ]]; then
    echo "Error: Backup policy file not found at ${POLICY_FILE}"
    exit 1
fi

# Initialize required environment variables from backup policy
AWS_REGION=$(aws configure get region)
BACKUP_BUCKET=$(jq -r '.backup_configuration.backup_resources.storage[] | select(.type=="S3") | .bucket' "${POLICY_FILE}")
RETENTION_DAYS=$(jq -r '.backup_configuration.backup_schedule.retention_period' "${POLICY_FILE}")
NOTIFICATION_TOPIC=$(jq -r '.backup_configuration.notifications.sns_topic_arn' "${POLICY_FILE}")
KMS_KEY_ID=$(jq -r '.backup_configuration.encryption.kms_key_id' "${POLICY_FILE}")
BACKUP_SCHEDULE=$(jq -r '.backup_configuration.backup_schedule.full_backup' "${POLICY_FILE}")

# Function to check prerequisites
check_prerequisites() {
    local exit_code=0

    # Check AWS CLI version
    if ! aws --version | grep -q "aws-cli/2"; then
        echo "Error: AWS CLI v2.0+ is required"
        exit_code=1
    fi

    # Check jq version
    if ! command -v jq >/dev/null || ! jq --version | grep -q "jq-1\.[6-9]"; then
        echo "Error: jq v1.6+ is required"
        exit_code=1
    fi

    # Check PostgreSQL client
    if ! command -v psql >/dev/null || ! psql --version | grep -q "15"; then
        echo "Error: PostgreSQL client tools v15 are required"
        exit_code=1
    fi

    # Verify environment variables
    local required_vars=("AWS_REGION" "BACKUP_BUCKET" "RETENTION_DAYS" "NOTIFICATION_TOPIC" "KMS_KEY_ID")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            echo "Error: Required environment variable ${var} is not set"
            exit_code=1
        fi
    done

    # Verify AWS permissions
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        echo "Error: Invalid AWS credentials or permissions"
        exit_code=1
    fi

    # Verify KMS key access
    if ! aws kms describe-key --key-id "${KMS_KEY_ID}" >/dev/null 2>&1; then
        echo "Error: Cannot access KMS key"
        exit_code=1
    fi

    # Verify S3 bucket
    if ! aws s3api head-bucket --bucket "${BACKUP_BUCKET}" 2>/dev/null; then
        echo "Error: Cannot access S3 bucket ${BACKUP_BUCKET}"
        exit_code=1
    fi

    return ${exit_code}
}

# Function to backup RDS database
backup_rds_database() {
    local db_identifier="$1"
    local snapshot_identifier="$2"
    local timestamp=$(date +%Y-%m-%d-%H-%M-%S)
    local snapshot_arn

    # Create RDS snapshot with tags
    echo "Creating RDS snapshot for ${db_identifier}"
    aws rds create-db-snapshot \
        --db-instance-identifier "${db_identifier}" \
        --db-snapshot-identifier "${snapshot_identifier}-${timestamp}" \
        --tags Key=BackupType,Value=Automated Key=Timestamp,Value="${timestamp}" \
        --region "${AWS_REGION}"

    # Wait for snapshot completion
    echo "Waiting for snapshot completion..."
    aws rds wait db-snapshot-available \
        --db-snapshot-identifier "${snapshot_identifier}-${timestamp}" \
        --region "${AWS_REGION}"

    # Export snapshot to S3 with encryption
    snapshot_arn=$(aws rds describe-db-snapshots \
        --db-snapshot-identifier "${snapshot_identifier}-${timestamp}" \
        --query 'DBSnapshots[0].DBSnapshotArn' \
        --output text)

    aws rds start-export-task \
        --source-arn "${snapshot_arn}" \
        --s3-bucket-name "${BACKUP_BUCKET}" \
        --s3-prefix "rds/${db_identifier}/${timestamp}" \
        --kms-key-id "${KMS_KEY_ID}" \
        --iam-role-arn "$(aws iam get-role --role-name rds-s3-export-role --query 'Role.Arn' --output text)"

    echo "${snapshot_arn}"
}

# Function to backup DynamoDB tables
backup_dynamodb_tables() {
    local table_names=("$@")
    local backup_status=()
    local timestamp=$(date +%Y-%m-%d-%H-%M-%S)

    for table in "${table_names[@]}"; do
        echo "Creating backup for DynamoDB table ${table}"
        local backup_arn=$(aws dynamodb create-backup \
            --table-name "${table}" \
            --backup-name "${table}-${timestamp}" \
            --region "${AWS_REGION}" \
            --query 'BackupDetails.BackupArn' \
            --output text)

        # Export to S3 with encryption
        aws dynamodb export-table-to-point-in-time \
            --table-arn "$(aws dynamodb describe-table --table-name ${table} --query 'Table.TableArn' --output text)" \
            --s3-bucket "${BACKUP_BUCKET}" \
            --s3-prefix "dynamodb/${table}/${timestamp}" \
            --export-format DYNAMODB_JSON \
            --kms-key-id "${KMS_KEY_ID}"

        backup_status+=("${table}:${backup_arn}")
    done

    echo "${backup_status[@]}"
}

# Function to cleanup old backups
cleanup_old_backups() {
    local retention_days="$1"
    local cutoff_date=$(date -d "${retention_days} days ago" +%Y-%m-%d)
    local cleanup_results=()

    # Cleanup RDS snapshots
    local old_snapshots=$(aws rds describe-db-snapshots \
        --query "DBSnapshots[?SnapshotCreateTime<='${cutoff_date}'].DBSnapshotIdentifier" \
        --output text)

    for snapshot in ${old_snapshots}; do
        aws rds delete-db-snapshot --db-snapshot-identifier "${snapshot}"
        cleanup_results+=("Deleted RDS snapshot: ${snapshot}")
    done

    # Cleanup S3 exports
    aws s3 rm "s3://${BACKUP_BUCKET}/rds/" \
        --recursive \
        --exclude "*" \
        --include "*${cutoff_date}*"

    aws s3 rm "s3://${BACKUP_BUCKET}/dynamodb/" \
        --recursive \
        --exclude "*" \
        --include "*${cutoff_date}*"

    echo "${cleanup_results[@]}"
}

# Function to send notifications
send_notification() {
    local message="$1"
    local status="$2"
    local timestamp=$(date --iso-8601=seconds)

    local notification_payload=$(cat <<EOF
{
    "backup_status": "${status}",
    "timestamp": "${timestamp}",
    "message": "${message}",
    "backup_configuration": {
        "region": "${AWS_REGION}",
        "bucket": "${BACKUP_BUCKET}",
        "kms_key": "${KMS_KEY_ID}"
    }
}
EOF
)

    local notification_id=$(aws sns publish \
        --topic-arn "${NOTIFICATION_TOPIC}" \
        --message "${notification_payload}" \
        --region "${AWS_REGION}" \
        --query 'MessageId' \
        --output text)

    echo "${notification_id}"
}

# Main backup orchestration function
backup_database() {
    local start_time=$(date +%s)
    local status="SUCCESS"
    local message=""

    # Check prerequisites
    if ! check_prerequisites; then
        send_notification "Backup prerequisites check failed" "FAILED"
        exit 1
    fi

    # Get database identifiers from policy
    local rds_dbs=$(jq -r '.backup_configuration.backup_resources.databases[] | select(.type=="PostgreSQL") | .identifier' "${POLICY_FILE}")
    local dynamodb_tables=$(aws dynamodb list-tables --query 'TableNames[]' --output text)

    # Perform RDS backups
    for db in ${rds_dbs}; do
        if ! backup_rds_database "${db}" "automated-backup"; then
            status="FAILED"
            message+="RDS backup failed for ${db}. "
        fi
    done

    # Perform DynamoDB backups
    if ! backup_dynamodb_tables ${dynamodb_tables}; then
        status="FAILED"
        message+="DynamoDB backup failed. "
    fi

    # Cleanup old backups
    if ! cleanup_old_backups "${RETENTION_DAYS}"; then
        message+="Backup cleanup failed. "
    fi

    # Calculate duration and send notification
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    message+="Backup operation completed in ${duration} seconds."
    
    send_notification "${message}" "${status}"

    if [[ "${status}" == "FAILED" ]]; then
        exit 1
    fi
}

# Main cleanup orchestration function
cleanup_backups() {
    if ! check_prerequisites; then
        send_notification "Cleanup prerequisites check failed" "FAILED"
        exit 1
    fi

    local message="Starting backup cleanup for items older than ${RETENTION_DAYS} days"
    send_notification "${message}" "STARTED"

    if cleanup_old_backups "${RETENTION_DAYS}"; then
        send_notification "Backup cleanup completed successfully" "SUCCESS"
    else
        send_notification "Backup cleanup failed" "FAILED"
        exit 1
    fi
}

# Execute backup if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    backup_database
fi