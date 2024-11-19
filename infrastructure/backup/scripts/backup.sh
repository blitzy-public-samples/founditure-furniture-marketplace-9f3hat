#!/bin/bash

# Human Tasks:
# 1. Ensure AWS credentials are configured with appropriate permissions
# 2. Verify KMS key 'backup-key-id' exists and is accessible
# 3. Configure SNS topic 'founditure-backup-notifications' in your AWS region
# 4. Set up log rotation for /var/log/founditure/backup.log
# 5. Verify MongoDB and PostgreSQL connection credentials are configured

# Required tool versions:
# aws-cli v2.0+
# jq v1.6+
# postgresql-client v14+
# mongodb-tools v6.0+

# REQ: Data Protection - Implements AES-256 encryption for data at rest and TLS 1.3 for data in transit
# REQ: Business Continuity - Executes automated backup mechanisms for disaster recovery
# REQ: Security Compliance - Ensures backup processes comply with ISO 27001 and data protection regulations

set -euo pipefail

# Global variables
export AWS_REGION=${AWS_REGION:-"us-east-1"}
BACKUP_CONFIG_PATH=${BACKUP_CONFIG_PATH:-"../backup-policy.json"}
LOG_PATH=${LOG_PATH:-"/var/log/founditure/backup.log"}
RETENTION_DAYS=${RETENTION_DAYS:-30}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEMP_DIR="/tmp/founditure_backup_${TIMESTAMP}"

# Logging function
log() {
    local level=$1
    local message=$2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [${level}] ${message}" | tee -a "${LOG_PATH}"
}

# Initialize backup environment
initialize_backup() {
    log "INFO" "Initializing backup environment"
    
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "${LOG_PATH}")"
    
    # Verify backup configuration exists
    if [[ ! -f "${BACKUP_CONFIG_PATH}" ]]; then
        log "ERROR" "Backup configuration not found at ${BACKUP_CONFIG_PATH}"
        return 1
    }

    # Verify AWS CLI installation and credentials
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        log "ERROR" "AWS credentials not configured or invalid"
        return 1
    }

    # Verify required tools
    local required_tools=("jq" "pg_dump" "mongodump" "aws")
    for tool in "${required_tools[@]}"; do
        if ! command -v "${tool}" >/dev/null 2>&1; then
            log "ERROR" "Required tool ${tool} not found"
            return 1
        fi
    done

    # Create temporary directory
    mkdir -p "${TEMP_DIR}"
    
    return 0
}

# PostgreSQL backup function
backup_postgresql() {
    local db_identifier=$1
    log "INFO" "Starting PostgreSQL backup for ${db_identifier}"

    # Create RDS snapshot with encryption
    local snapshot_id="founditure-${db_identifier}-${TIMESTAMP}"
    if ! aws rds create-db-snapshot \
        --db-instance-identifier "${db_identifier}" \
        --db-snapshot-identifier "${snapshot_id}" \
        --tags Key=BackupType,Value=Automated Key=Timestamp,Value="${TIMESTAMP}"; then
        log "ERROR" "Failed to create RDS snapshot for ${db_identifier}"
        return 1
    }

    # Wait for snapshot completion
    aws rds wait db-snapshot-available --db-snapshot-identifier "${snapshot_id}"

    # Validate snapshot
    local snapshot_status=$(aws rds describe-db-snapshots \
        --db-snapshot-identifier "${snapshot_id}" \
        --query 'DBSnapshots[0].Status' --output text)

    if [[ "${snapshot_status}" != "available" ]]; then
        log "ERROR" "Snapshot validation failed for ${db_identifier}"
        return 1
    }

    # Clean up old snapshots
    local old_snapshots=$(aws rds describe-db-snapshots \
        --query "DBSnapshots[?DBInstanceIdentifier=='${db_identifier}'].[DBSnapshotIdentifier]" \
        --output text)

    for snapshot in ${old_snapshots}; do
        local snapshot_date=$(aws rds describe-db-snapshots \
            --db-snapshot-identifier "${snapshot}" \
            --query 'DBSnapshots[0].SnapshotCreateTime' --output text)
        
        if [[ $(date -d "${snapshot_date}" +%s) -lt $(date -d "-${RETENTION_DAYS} days" +%s) ]]; then
            aws rds delete-db-snapshot --db-snapshot-identifier "${snapshot}"
        fi
    done

    return 0
}

# MongoDB backup function
backup_mongodb() {
    local db_identifier=$1
    log "INFO" "Starting MongoDB backup for ${db_identifier}"

    # Execute MongoDB backup with TLS 1.3
    if ! mongodump \
        --uri="mongodb://${db_identifier}" \
        --ssl \
        --tlsVersion="TLS1_3" \
        --out="${TEMP_DIR}/${db_identifier}"; then
        log "ERROR" "MongoDB backup failed for ${db_identifier}"
        return 1
    }

    # Upload to S3 with encryption
    local backup_bucket="founditure-backups"
    local backup_key="mongodb/${db_identifier}/${TIMESTAMP}"

    if ! aws s3 cp \
        "${TEMP_DIR}/${db_identifier}" \
        "s3://${backup_bucket}/${backup_key}" \
        --recursive \
        --sse aws:kms \
        --sse-kms-key-id backup-key-id; then
        log "ERROR" "Failed to upload MongoDB backup to S3"
        return 1
    }

    # Verify backup integrity
    if ! aws s3api head-object \
        --bucket "${backup_bucket}" \
        --key "${backup_key}/admin/system.version.bson"; then
        log "ERROR" "MongoDB backup integrity check failed"
        return 1
    }

    return 0
}

# S3 backup function
backup_s3() {
    local bucket_name=$1
    log "INFO" "Starting S3 backup for ${bucket_name}"

    # Sync bucket with encryption
    if ! aws s3 sync \
        "s3://${bucket_name}" \
        "s3://backup-${bucket_name}" \
        --sse aws:kms \
        --sse-kms-key-id backup-key-id; then
        log "ERROR" "S3 sync failed for ${bucket_name}"
        return 1
    }

    return 0
}

# EFS backup function
backup_efs() {
    local filesystem_id=$1
    log "INFO" "Starting EFS backup for ${filesystem_id}"

    # Create EFS backup
    if ! aws backup start-backup-job \
        --backup-vault-name "founditure-backup-vault" \
        --resource-arn "arn:aws:elasticfilesystem:${AWS_REGION}:${filesystem_id}" \
        --iam-role-arn "arn:aws:iam::backup-role" \
        --start-window-minutes 60 \
        --complete-window-minutes 120 \
        --lifecycle DeleteAfterDays=${RETENTION_DAYS}; then
        log "ERROR" "EFS backup failed for ${filesystem_id}"
        return 1
    }

    return 0
}

# Backup validation function
validate_backup() {
    local backup_id=$1
    local backup_type=$2
    log "INFO" "Validating backup ${backup_id} of type ${backup_type}"

    case "${backup_type}" in
        "postgresql")
            local snapshot_status=$(aws rds describe-db-snapshots \
                --db-snapshot-identifier "${backup_id}" \
                --query 'DBSnapshots[0].Status' --output text)
            [[ "${snapshot_status}" != "available" ]] && return 1
            ;;
        "mongodb")
            local object_exists=$(aws s3 ls "s3://founditure-backups/mongodb/${backup_id}" || echo "")
            [[ -z "${object_exists}" ]] && return 1
            ;;
        "s3")
            local sync_status=$(aws s3api head-bucket --bucket "backup-${backup_id}" 2>&1 || echo "failed")
            [[ "${sync_status}" == "failed" ]] && return 1
            ;;
        "efs")
            local backup_status=$(aws backup describe-backup-job --backup-job-id "${backup_id}" \
                --query 'State' --output text)
            [[ "${backup_status}" != "COMPLETED" ]] && return 1
            ;;
    esac

    return 0
}

# Notification function
send_notification() {
    local message=$1
    local status=$2
    
    # Load SNS topic ARN from backup configuration
    local sns_topic_arn=$(jq -r '.backup_configuration.notifications.sns_topic_arn' "${BACKUP_CONFIG_PATH}")
    
    # Send notification
    if ! aws sns publish \
        --topic-arn "${sns_topic_arn}" \
        --message "${message}" \
        --subject "Founditure Backup ${status}"; then
        log "ERROR" "Failed to send notification"
        return 1
    }
    
    return 0
}

# Cleanup function
cleanup() {
    log "INFO" "Performing cleanup operations"
    
    # Remove temporary directory
    rm -rf "${TEMP_DIR}"
    
    # Compress logs older than 7 days
    find "$(dirname "${LOG_PATH}")" -name "*.log" -mtime +7 -exec gzip {} \;
    
    return 0
}

# Main execution flow
main() {
    local exit_code=0
    
    # Initialize backup environment
    if ! initialize_backup; then
        send_notification "Backup initialization failed" "FAILED"
        exit 1
    fi

    # Load backup configuration
    local config=$(cat "${BACKUP_CONFIG_PATH}")
    
    # Process PostgreSQL databases
    while IFS= read -r db; do
        if ! backup_postgresql "${db}"; then
            exit_code=1
            send_notification "PostgreSQL backup failed for ${db}" "FAILED"
        fi
    done < <(echo "${config}" | jq -r '.backup_configuration.backup_resources.databases[] | select(.type=="PostgreSQL") | .identifier')

    # Process MongoDB databases
    while IFS= read -r db; do
        if ! backup_mongodb "${db}"; then
            exit_code=1
            send_notification "MongoDB backup failed for ${db}" "FAILED"
        fi
    done < <(echo "${config}" | jq -r '.backup_configuration.backup_resources.databases[] | select(.type=="MongoDB") | .identifier')

    # Process S3 buckets
    while IFS= read -r bucket; do
        if ! backup_s3 "${bucket}"; then
            exit_code=1
            send_notification "S3 backup failed for ${bucket}" "FAILED"
        fi
    done < <(echo "${config}" | jq -r '.backup_configuration.backup_resources.storage[] | select(.type=="S3") | .bucket')

    # Process EFS filesystems
    while IFS= read -r fs; do
        if ! backup_efs "${fs}"; then
            exit_code=1
            send_notification "EFS backup failed for ${fs}" "FAILED"
        fi
    done < <(echo "${config}" | jq -r '.backup_configuration.backup_resources.storage[] | select(.type=="EFS") | .identifier')

    # Perform cleanup
    cleanup

    # Send final notification
    if [[ ${exit_code} -eq 0 ]]; then
        send_notification "All backup operations completed successfully" "SUCCESS"
    else
        send_notification "Some backup operations failed, check logs for details" "PARTIAL_FAILURE"
    fi

    return ${exit_code}
}

# Execute main function
main