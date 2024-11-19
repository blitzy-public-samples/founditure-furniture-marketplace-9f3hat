#!/bin/bash

# Human Tasks:
# 1. Ensure AWS credentials are properly configured with sufficient permissions
# 2. Verify that the target environment's tfvars file exists and is properly configured
# 3. Review cost estimation before applying changes in production
# 4. Ensure proper backup of existing state files before major changes
# 5. Validate that required IAM roles and policies are in place

# Required versions
# terraform: >=1.0.0
# aws-cli: >=2.0.0

# Source initialization script for shared functions
source ./init-terraform.sh

# Requirement: Multi-Environment Infrastructure
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
SUPPORTED_ENVIRONMENTS=("dev" "staging" "prod")
PLAN_FILE_PATH="./terraform.plan"
AUTO_APPROVE_ENVS=("dev")

# Requirement: Infrastructure as Code
# Location: 6. INFRASTRUCTURE/6.4 CI/CD PIPELINE/Pipeline Stages
validate_plan() {
    local environment=$1
    echo "Validating Terraform plan for environment: ${environment}"

    # Validate environment
    if [[ ! " ${SUPPORTED_ENVIRONMENTS[@]} " =~ " ${environment} " ]]; then
        echo "Error: Invalid environment. Supported environments: ${SUPPORTED_ENVIRONMENTS[*]}"
        return 1
    }

    # Run terraform plan with environment-specific variables
    if ! terraform plan \
        -var-file="environments/${environment}/terraform.tfvars" \
        -out="${PLAN_FILE_PATH}"; then
        echo "Error: Terraform plan failed"
        return 1
    }

    # Check for destructive changes
    if terraform show -json "${PLAN_FILE_PATH}" | jq -r '.resource_changes[] | select(.change.actions[] | contains("delete"))' | grep .; then
        if [[ ! " ${AUTO_APPROVE_ENVS[@]} " =~ " ${environment} " ]]; then
            echo "Warning: Plan contains destructive changes. Manual approval required."
            read -p "Do you want to proceed? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                return 1
            fi
        fi
    fi

    return 0
}

# Requirement: Security Controls
# Location: 5. SECURITY CONSIDERATIONS/5.2 DATA SECURITY
apply_changes() {
    local environment=$1
    local plan_file=$2
    echo "Applying Terraform changes for environment: ${environment}"

    # Verify workspace matches target environment
    current_workspace=$(terraform workspace show)
    if [[ "${current_workspace}" != "${environment}" ]]; then
        echo "Error: Current workspace (${current_workspace}) does not match target environment (${environment})"
        return 1
    }

    # Apply terraform changes
    if ! terraform apply -auto-approve "${plan_file}"; then
        echo "Error: Terraform apply failed"
        return 1
    }

    # Backup state file
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="terraform.tfstate.backup.${timestamp}"
    cp terraform.tfstate "${backup_file}"
    echo "State file backed up to: ${backup_file}"

    return 0
}

# Requirement: Infrastructure as Code
# Location: 6. INFRASTRUCTURE/6.4 CI/CD PIPELINE/Pipeline Stages
handle_error() {
    local error_message=$1
    local error_code=$2

    echo "Error: ${error_message}"
    
    # Cleanup temporary files
    if [[ -f "${PLAN_FILE_PATH}" ]]; then
        rm "${PLAN_FILE_PATH}"
    fi

    # Log error details
    local timestamp=$(date +%Y-%m-%d_%H:%M:%S)
    echo "[${timestamp}] Error (${error_code}): ${error_message}" >> terraform-error.log

    return 1
}

# Requirement: Multi-Environment Infrastructure
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
main() {
    # Parse command line arguments
    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 <environment>"
        echo "Supported environments: ${SUPPORTED_ENVIRONMENTS[*]}"
        return 1
    }

    local environment=$1

    # Check prerequisites
    if ! check_prerequisites; then
        handle_error "Prerequisites check failed" 1
        return 1
    fi

    # Validate terraform plan
    if ! validate_plan "${environment}"; then
        handle_error "Plan validation failed" 2
        return 1
    fi

    # Apply terraform changes
    if ! apply_changes "${environment}" "${PLAN_FILE_PATH}"; then
        handle_error "Apply changes failed" 3
        return 1
    fi

    # Cleanup
    if [[ -f "${PLAN_FILE_PATH}" ]]; then
        rm "${PLAN_FILE_PATH}"
    fi

    echo "Successfully applied Terraform changes for environment: ${environment}"
    return 0
}

# Execute main function with provided arguments
main "$@"