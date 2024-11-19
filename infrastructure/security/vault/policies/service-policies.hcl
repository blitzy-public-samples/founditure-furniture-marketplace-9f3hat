# Human Tasks:
# 1. Verify that all secret paths exist in Vault before applying policies
# 2. Ensure AWS service credentials are properly stored in shared secret paths
# 3. Validate service account names match Kubernetes deployments
# 4. Confirm proper secret engine mounting at 'secret/founditure/'

# Requirement: 5.2.1 Encryption Standards - Implementation of secure access policies
# AI Service Policy - Access to AI-specific secrets and AWS Rekognition credentials
path "secret/founditure/ai-service/*" {
    capabilities = ["read", "list"]
    description = "Access to AI service specific secrets"
}

path "secret/founditure/shared/aws-rekognition" {
    capabilities = ["read"]
    description = "Access to shared AWS Rekognition credentials"
}

# Requirement: 5.1.2 Authorization Model - Service-level authorization
# Listing Service Policy - Access to listing-specific secrets and S3 storage credentials
path "secret/founditure/listing-service/*" {
    capabilities = ["read", "list"]
    description = "Access to Listing service specific secrets"
}

path "secret/founditure/shared/s3-storage" {
    capabilities = ["read"]
    description = "Access to shared S3 storage credentials"
}

# Requirement: 5.3.2 Security Controls - Strict path-based permissions
# Messaging Service Policy - Access to messaging-specific secrets and SQS/SNS credentials
path "secret/founditure/messaging-service/*" {
    capabilities = ["read", "list"]
    description = "Access to Messaging service specific secrets"
}

path "secret/founditure/shared/sqs-credentials" {
    capabilities = ["read"]
    description = "Access to shared SQS/SNS credentials"
}

# Requirement: 5.2.1 Encryption Standards - Secure credential access
# Notification Service Policy - Access to notification-specific secrets and SES/SNS credentials
path "secret/founditure/notification-service/*" {
    capabilities = ["read", "list"]
    description = "Access to Notification service specific secrets"
}

path "secret/founditure/shared/ses-credentials" {
    capabilities = ["read"]
    description = "Access to shared SES credentials"
}

# Requirement: 5.3.2 Security Controls - Fine-grained access control
# Location Service Policy - Access to location-specific secrets and AWS Location Service credentials
path "secret/founditure/location-service/*" {
    capabilities = ["read", "list"]
    description = "Access to Location service specific secrets"
}

path "secret/founditure/shared/maps-credentials" {
    capabilities = ["read"]
    description = "Access to shared AWS Location Service credentials"
}

# Requirement: 5.1.2 Authorization Model - Least privilege access
# Gamification Service Policy - Access to gamification-specific secrets and DynamoDB credentials
path "secret/founditure/gamification-service/*" {
    capabilities = ["read", "list"]
    description = "Access to Gamification service specific secrets"
}

path "secret/founditure/shared/dynamodb-credentials" {
    capabilities = ["read"]
    description = "Access to shared DynamoDB credentials"
}

# Common deny rules to prevent access to other paths
path "secret/founditure/+" {
    capabilities = ["deny"]
    description = "Explicitly deny access to other service paths"
}

path "secret/founditure/shared/+" {
    capabilities = ["deny"]
    description = "Explicitly deny access to other shared credential paths"
}

# System paths - deny by default
path "sys/*" {
    capabilities = ["deny"]
    description = "Deny access to system paths"
}

# Auth paths - deny by default
path "auth/*" {
    capabilities = ["deny"]
    description = "Deny access to auth paths"
}