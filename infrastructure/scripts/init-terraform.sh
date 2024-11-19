#!/bin/bash

# Human Tasks:
# 1. Ensure AWS credentials are properly configured with sufficient permissions
# 2. Verify S3 bucket creation permissions in target AWS account
# 3. Confirm DynamoDB table creation permissions
# 4. Review backend encryption settings match security requirements
# 5. Validate AWS CLI version >= 2.0.0 is installed
# 6. Ensure Terraform version >= 1.0.0 is installed

# Required versions
TERRAFORM_VERSION=">=1.0.0"
STATE_BUCKET_PREFIX="founditure-terraform-state"
LOCK_TABLE_NAME="founditure-terraform-locks"
SUPPORTED_ENVIRONMENTS=("dev" "staging" "prod")

# Requirement: Multi-Environment Infrastructure
# Location: 6. INFRASTRUCTURE/6.1 DEPLOYMENT ENVIRONMENT/Environment Specifications
check_prerequisites() {
    echo "Checking prerequisites..."
    
    # Check Terraform version
    if ! command -v terraform &> /dev/null; then
        echo "Error: Terraform is not installed"
        return 1
    fi
    
    terraform_version=$(terraform version -json | jq -r '.terraform_version')
    if ! echo "$terraform_version" | grep -q "^1\."; then
        echo "Error: Terraform version must be ${TERRAFORM_VERSION}"
        return 1
    fi
    
    # Check AWS CLI version
    if ! command -v aws &> /dev/null; then
        echo "Error: AWS CLI is not installed"
        return 1
    fi
    
    aws_version=$(aws --version 2>&1 | cut -d/ -f2 | cut -d' ' -f1)
    if [[ ! "$aws_version" =~ ^2\. ]]; then
        echo "Error: AWS CLI version must be >= 2.0.0"
        return 1
    }
    
    # Verify AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "Error: Invalid AWS credentials"
        return 1
    }
    
    # Check required environment variables
    if [[ -z "${AWS_REGION}" ]]; then
        echo "Error: AWS_REGION environment variable is not set"
        return 1
    }
    
    if [[ -z "${AWS_PROFILE}" ]]; then
        echo "Error: AWS_PROFILE environment variable is not set"
        return 1
    }
    
    return 0
}

# Requirement: Infrastructure as Code
# Location: 6. INFRASTRUCTURE/6.4 CI/CD PIPELINE/Pipeline Stages
setup_backend() {
    local environment=$1
    echo "Setting up Terraform backend for environment: ${environment}"
    
    # Create S3 bucket if it doesn't exist
    local bucket_name="${STATE_BUCKET_PREFIX}-${environment}"
    if ! aws s3api head-bucket --bucket "${bucket_name}" 2>/dev/null; then
        echo "Creating S3 bucket: ${bucket_name}"
        aws s3api create-bucket \
            --bucket "${bucket_name}" \
            --region "${AWS_REGION}" \
            --create-bucket-configuration LocationConstraint="${AWS_REGION}"
        
        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket "${bucket_name}" \
            --versioning-configuration Status=Enabled
        
        # Enable encryption
        aws s3api put-bucket-encryption \
            --bucket "${bucket_name}" \
            --server-side-encryption-configuration '{
                "Rules": [
                    {
                        "ApplyServerSideEncryptionByDefault": {
                            "SSEAlgorithm": "AES256"
                        }
                    }
                ]
            }'
    fi
    
    # Create DynamoDB table if it doesn't exist
    if ! aws dynamodb describe-table --table-name "${LOCK_TABLE_NAME}" &>/dev/null; then
        echo "Creating DynamoDB table: ${LOCK_TABLE_NAME}"
        aws dynamodb create-table \
            --table-name "${LOCK_TABLE_NAME}" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region "${AWS_REGION}"
        
        aws dynamodb wait table-exists --table-name "${LOCK_TABLE_NAME}"
    fi
    
    return 0
}

# Requirement: Security Controls
# Location: 5. SECURITY CONSIDERATIONS/5.2 DATA SECURITY
init_workspace() {
    local environment=$1
    echo "Initializing Terraform workspace for environment: ${environment}"
    
    # Validate environment
    if [[ ! " ${SUPPORTED_ENVIRONMENTS[@]} " =~ " ${environment} " ]]; then
        echo "Error: Invalid environment. Supported environments: ${SUPPORTED_ENVIRONMENTS[*]}"
        return 1
    }
    
    # Create and select workspace
    if ! terraform workspace select "${environment}" 2>/dev/null; then
        echo "Creating new workspace: ${environment}"
        terraform workspace new "${environment}"
    fi
    
    # Copy environment-specific tfvars
    local tfvars_source="../terraform/environments/${environment}/terraform.tfvars"
    local tfvars_dest="terraform.tfvars"
    
    if [[ ! -f "${tfvars_source}" ]]; then
        echo "Error: Environment tfvars file not found: ${tfvars_source}"
        return 1
    fi
    
    cp "${tfvars_source}" "${tfvars_dest}"
    
    # Validate Terraform configuration
    if ! terraform validate; then
        echo "Error: Terraform configuration validation failed"
        return 1
    }
    
    return 0
}

# Main script execution
main() {
    # Parse command line arguments
    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 <environment>"
        echo "Supported environments: ${SUPPORTED_ENVIRONMENTS[*]}"
        exit 1
    fi
    
    local environment=$1
    
    # Execute initialization steps
    if ! check_prerequisites; then
        echo "Error: Prerequisites check failed"
        exit 1
    fi
    
    if ! setup_backend "${environment}"; then
        echo "Error: Backend setup failed"
        exit 1
    fi
    
    if ! init_workspace "${environment}"; then
        echo "Error: Workspace initialization failed"
        exit 1
    }
    
    # Initialize Terraform with backend configuration
    echo "Initializing Terraform..."
    if ! terraform init \
        -backend=true \
        -backend-config="bucket=${STATE_BUCKET_PREFIX}-${environment}" \
        -backend-config="key=${environment}/terraform.tfstate" \
        -backend-config="region=${AWS_REGION}" \
        -backend-config="dynamodb_table=${LOCK_TABLE_NAME}" \
        -backend-config="encrypt=true"; then
        echo "Error: Terraform initialization failed"
        exit 1
    fi
    
    echo "Terraform initialization completed successfully!"
    echo "Next steps:"
    echo "1. Review terraform plan output"
    echo "2. Apply terraform configuration"
    echo "3. Verify resources in AWS console"
    
    return 0
}

# Execute main function with provided arguments
main "$@"