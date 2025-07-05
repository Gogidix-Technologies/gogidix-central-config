# Infrastructure as Code - Setup Guide

## Overview

This document provides comprehensive setup instructions for the Infrastructure as Code (IaC) service, which manages the provisioning and configuration of cloud resources across the Social E-commerce Ecosystem.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development Setup](#local-development-setup)
3. [Configuration Management](#configuration-management)
4. [Provider Configuration](#provider-configuration)
5. [Module Structure](#module-structure)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- **Operating System**: Windows 10/11, macOS 10.15+, Linux Ubuntu 18.04+
- **Memory**: 8GB RAM minimum (16GB recommended)
- **Storage**: 10GB free space
- **Network**: Internet access for provider plugins and modules

### Required Software

```bash
# Core Tools
Terraform 1.4+
AWS CLI 2.9+
Azure CLI 2.45+ (if using Azure)
Google Cloud SDK 420.0.0+ (if using GCP)

# Version Control
Git 2.30+

# Container Tools (Optional)
Docker 20.10+
Kubernetes CLI 1.24+

# Security Tools
GPG 2.3+ (for secrets management)
SOPS 3.7+ (for encrypted secrets)
```

### Cloud Provider Access

- AWS IAM credentials with appropriate permissions
- Azure Service Principal (if using Azure)
- Google Cloud Service Account (if using GCP)
- Required API keys and credentials

## Local Development Setup

### 1. Clone Repository

```bash
git clone https://github.com/gogidix-social-ecommerce-ecosystem/central-configuration.git
cd central-configuration/infrastructure-as-code
```

### 2. Configure Environment

Create a `.env` file from the template:

```bash
cp .env.template .env
```

Edit `.env` with your configuration:

```
# Environment Configuration
ENVIRONMENT=dev
REGION=us-west-2

# AWS Configuration
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_DEFAULT_REGION=${REGION}

# State Storage
TF_STATE_BUCKET=gogidix-tf-state-${ENVIRONMENT}
TF_STATE_KEY=infrastructure/terraform.tfstate
TF_STATE_REGION=${REGION}

# Remote Backend Configuration
TF_BACKEND=s3
```

### 3. Initialize Terraform

```bash
# Install required providers
terraform init -backend-config=environments/${ENVIRONMENT}/backend.hcl

# Verify provider installation
terraform providers
```

### 4. Set Up Remote State (First Time Only)

```bash
# Create S3 bucket for remote state (if not exists)
aws s3api create-bucket \
  --bucket ${TF_STATE_BUCKET} \
  --region ${TF_STATE_REGION} \
  --create-bucket-configuration LocationConstraint=${TF_STATE_REGION}

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket ${TF_STATE_BUCKET} \
  --versioning-configuration Status=Enabled
```

### 5. Verify Setup

```bash
# Validate configuration
terraform validate

# Check execution plan
terraform plan -var-file=environments/${ENVIRONMENT}/variables.tfvars
```

## Configuration Management

### Directory Structure

```
infrastructure-as-code/
├── modules/                  # Reusable modules
│   ├── networking/           # Network resources
│   ├── compute/              # Compute resources
│   ├── database/             # Database resources
│   ├── security/             # IAM, policies, etc.
│   └── monitoring/           # Monitoring and logging
├── environments/             # Environment-specific configs
│   ├── dev/
│   │   ├── backend.hcl
│   │   ├── variables.tfvars
│   │   └── terraform.tfvars
│   ├── staging/
│   └── prod/
├── scripts/                  # Utility scripts
└── main.tf                   # Root module
```

### Environment Configuration

Each environment should have its own configuration in the `environments` directory:

```hcl
# environments/dev/backend.hcl
bucket         = "gogidix-tf-state-dev"
key            = "infrastructure/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "terraform-locks"
encrypt        = true
```

## Provider Configuration

### AWS Provider

```hcl
# providers.tf
provider "aws" {
  region = var.region
  
  # Assume role for cross-account access (if needed)
  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/TerraformRole"
  }
  
  # Enable debug logging
  debug_log = "aws_debug.log"
  
  # Required tags for all resources
  default_tags {
    tags = {
      Environment = var.environment
      Terraform   = "true"
      Project     = "Social-Ecommerce-Ecosystem"
    }
  }
}
```

### Remote State Configuration

```hcl
# backend.tf
terraform {
  backend "s3" {
    # This will be overridden by -backend-config
    # Actual values are in environments/<env>/backend.hcl
  }
}
```

## Module Structure

### Example Module: VPC

```hcl
# modules/networking/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-vpc"
    }
  )
}

# Add other VPC resources (subnets, route tables, etc.)
```

## Verification

### Validate Configuration

```bash
# Check syntax
terraform fmt -check

# Validate configuration
terraform validate

# Generate execution plan
terraform plan -var-file=environments/${ENVIRONMENT}/variables.tfvars
```

### Apply Changes

```bash
# Apply changes with approval
terraform apply -var-file=environments/${ENVIRONMENT}/variables.tfvars

# Auto-approve for CI/CD
terraform apply -auto-approve -var-file=environments/${ENVIRONMENT}/variables.tfvars
```

## Troubleshooting

### Common Issues

#### State Locking Issues

```bash
# Check for locks
aws dynamodb scan --table-name terraform-locks

# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

#### Authentication Errors

1. Verify AWS credentials are set:
   ```bash
   aws sts get-caller-identity
   ```

2. Check IAM permissions
3. Verify MFA is configured if required

#### Provider Plugin Issues

```bash
# Clean plugin cache
rm -rf .terraform/

# Reinitialize
terraform init
```

### Debugging

```bash
# Enable debug logging
TF_LOG=DEBUG terraform plan

# Check AWS debug logs
cat aws_debug.log
```

### State Management

```bash
# List resources in state
terraform state list

# Inspect a resource
terraform state show aws_vpc.main

# Import existing resources
terraform import aws_vpc.main vpc-12345678

# Move resources in state
terraform state mv module.old_vpc.aws_vpc.main module.new_vpc.aws_vpc.main
```
