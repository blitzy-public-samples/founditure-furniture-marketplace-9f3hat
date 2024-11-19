#!/bin/bash

# Human Tasks:
# 1. Ensure AWS CLI v2+ is installed and configured with appropriate credentials for each environment
# 2. Verify Terraform v1.0.0+ is installed and properly initialized
# 3. Review and configure environment-specific approval requirements in REQUIRE_APPROVAL
# 4. Set up backup storage location with appropriate permissions
# 5. Configure AWS credentials with sufficient permissions for resource destruction

set -euo pipefail

# External Dependencies:
# terraform >= 1.0.0
# aws-cli >= 2.0.0

# Global Configuration
TERRAFORM_VERSION=">=1.0.0"
SUPPORTED_ENVIRONMENTS=["dev", "staging", "prod"]
BACKUP_DIR="/tmp/founditure-backups"
REQUIRE_APPROVAL={"dev": false, "staging": true, "prod": true}

# Source relative path to backup script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/backup-database.sh"

# REQ: Multi-Environment Infrastructure - Supports safe destruction of resources across environments
check_environment() {
    local environment="$1"
    local exit_code=0

    echo "Validating environment: ${environment}"

    # Validate environment is supported
    if [[ ! "${SUPPORTED_ENVIRONMENTS[@]}" =~ "${environment}" ]]; then
        echo "Error: Invalid environment. Must be one of: ${SUPPORTED_ENVIRONMENTS[*]}"
        return 1
    }

    # Check if environment requires approval
    if [[ "${REQUIRE_APPROVAL[${environment}]}" == "true" ]]; then
        read -p "WARNING: Destroying ${environment} environment requires approval. Continue? (y/N): " confirm
        if [[ "${confirm}" != "y" ]]; then
            echo "Destruction aborted by user"
            return 1
        fi
    fi

    # Verify AWS credentials
    echo "Verifying AWS credentials..."
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        echo "Error: Invalid AWS credentials"
        return 1
    fi

    # Verify AWS account matches environment
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local expected_account_id
    case "${environment}" in
        dev) expected_account_id="YOUR_DEV_ACCOUNT_ID" ;;
        staging) expected_account_id="YOUR_STAGING_ACCOUNT_ID" ;;
        prod) expected_account_id="YOUR_PROD_ACCOUNT_ID" ;;
    esac

    if [[ "${account_id}" != "${expected_account_id}" ]]; then
        echo "Error: AWS account mismatch for environment ${environment}"
        return 1
    }

    # Verify Terraform workspace
    echo "Verifying Terraform workspace..."
    local current_workspace=$(terraform workspace show)
    if [[ "${current_workspace}" != "${environment}" ]]; then
        echo "Error: Current Terraform workspace (${current_workspace}) does not match target environment (${environment})"
        return 1
    }

    # Validate environment variable exists in variables.tf
    if ! terraform validate >/dev/null 2>&1; then
        echo "Error: Terraform configuration validation failed"
        return 1
    }

    return ${exit_code}
}

# REQ: Data Protection - Ensures proper backup before destroying infrastructure resources
backup_resources() {
    local environment="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${BACKUP_DIR}/${environment}_${timestamp}"
    
    echo "Creating backup directory: ${backup_path}"
    mkdir -p "${backup_path}"

    # Export Terraform state
    echo "Exporting Terraform state..."
    if ! terraform state pull > "${backup_path}/terraform.tfstate"; then
        echo "Error: Failed to export Terraform state"
        return 1
    fi

    # Backup database using imported function
    echo "Backing up database..."
    if ! backup_database; then
        echo "Error: Database backup failed"
        return 1
    }

    # Backup configuration files
    echo "Backing up configuration files..."
    cp -r ../terraform "${backup_path}/terraform_config"
    
    # Archive logs and metrics
    echo "Archiving logs and metrics..."
    if [[ -d "../logs" ]]; then
        tar czf "${backup_path}/logs.tar.gz" ../logs
    fi

    # Verify backup integrity
    echo "Verifying backup integrity..."
    if ! find "${backup_path}" -type f -exec md5sum {} + > "${backup_path}/checksums.md5"; then
        echo "Error: Failed to generate backup checksums"
        return 1
    }

    echo "Backup completed successfully at ${backup_path}"
    return 0
}

# REQ: Infrastructure as Code - Enables automated infrastructure teardown
destroy_infrastructure() {
    local environment="$1"
    local force="$2"
    local exit_code=0

    echo "Initializing Terraform..."
    if ! terraform init; then
        echo "Error: Terraform initialization failed"
        return 1
    fi

    # Select correct workspace
    echo "Selecting workspace: ${environment}"
    terraform workspace select "${environment}"

    # Generate destroy plan
    echo "Generating destroy plan..."
    if ! terraform plan -destroy -out=destroy.tfplan; then
        echo "Error: Failed to generate destroy plan"
        return 1
    }

    # Display resources to be destroyed
    echo "Resources to be destroyed:"
    terraform show destroy.tfplan

    # Confirm destruction
    if [[ "${force}" != "true" ]]; then
        read -p "Do you want to proceed with destruction? (y/N): " confirm
        if [[ "${confirm}" != "y" ]]; then
            echo "Destruction aborted by user"
            return 1
        fi
    fi

    # Execute destroy
    echo "Executing Terraform destroy..."
    if ! terraform apply destroy.tfplan; then
        echo "Error: Terraform destroy failed"
        exit_code=1
    fi

    # Verify resources are removed
    echo "Verifying resource removal..."
    if aws resourcegroupstaggingapi get-resources --tag-filters "Key=Environment,Values=${environment}" --query 'ResourceTagMappingList[].ResourceARN' --output text | grep -q .; then
        echo "Warning: Some resources may still exist"
        exit_code=1
    fi

    # Clean up local files
    rm -f destroy.tfplan
    rm -rf .terraform/plans

    return ${exit_code}
}

# Main execution function
main() {
    local environment=""
    local force=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --environment|-e)
                environment="$2"
                shift 2
                ;;
            --force|-f)
                force=true
                shift
                ;;
            *)
                echo "Usage: $0 --environment <dev|staging|prod> [--force]"
                exit 1
                ;;
        esac
    done

    if [[ -z "${environment}" ]]; then
        echo "Error: Environment must be specified"
        exit 1
    fi

    # Execute destruction process
    if ! check_environment "${environment}"; then
        exit 1
    fi

    if ! backup_resources "${environment}"; then
        exit 1
    fi

    if ! destroy_infrastructure "${environment}" "${force}"; then
        exit 1
    fi

    echo "Infrastructure destruction completed successfully"
    
    # Clean up backup directory after 7 days
    find "${BACKUP_DIR}" -type d -mtime +7 -exec rm -rf {} +

    return 0
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi